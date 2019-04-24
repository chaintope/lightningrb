# frozen_string_literal: true

module Lightning
  module Crypto
    class TransportHandler < Concurrent::Actor::Context
      include Lightning::Wire::HandshakeMessages

      PREFIX = '00'.htb.freeze
      PROLOGUE = '6c696768746e696e67'.htb.freeze

      attr_reader :static_key, :remote_key

      def initialize(static_key, session, remote_key: nil)
        @static_key = static_key
        @remote_key = remote_key

        session << self

        @connection =
          if initiator?
            make_writer.tap(&:start_handshake).tap do |connection|
              payload = connection.write_message('')
              self.reference.parent << Act[PREFIX + payload, session]
            end
          else
            make_reader.tap(&:start_handshake)
          end
        @status = TransportHandlerStateHandshake.new(self, session, @static_key, @connection)
      end

      def on_message(message)
        @status = @status.next(message)
      end

      def initiator?
        !@remote_key.nil?
      end

      def create_ephemeral_private_key
        Bitcoin::Key.generate.priv_key
      end

      def make_writer
        initiator = Noise::Connection.new('Noise_XK_secp256k1_ChaChaPoly_SHA256')
        initiator.prologue = PROLOGUE
        initiator.set_as_initiator!
        initiator.set_keypair_from_private(Noise::KeyPair::STATIC, @static_key.htb)
        initiator.set_keypair_from_private(Noise::KeyPair::EPHEMERAL, create_ephemeral_private_key.htb)
        initiator.set_keypair_from_public(Noise::KeyPair::REMOTE_STATIC, @remote_key.htb)
        initiator
      end

      def make_reader
        responder = Noise::Connection.new('Noise_XK_secp256k1_ChaChaPoly_SHA256')
        responder.prologue = PROLOGUE
        responder.set_as_responder!
        responder.set_keypair_from_private(Noise::KeyPair::STATIC, @static_key.htb)
        responder.set_keypair_from_private(Noise::KeyPair::EPHEMERAL, create_ephemeral_private_key.htb)
        responder
      end

      def to_s
        "TransportHandler @static_key = #{static_key} @remote_key = #{remote_key}"
      end

      def inspect
        "TransportHandler @static_key = #{static_key} @remote_key = #{remote_key}"
      end

      class TransportHandlerState
        include Concurrent::Concern::Logging
        include Algebrick::Matching
        include Lightning::Exceptions
        include Lightning::Wire::HandshakeMessages
        include Lightning::Wire::LightningMessages

        def initialize(actor, session, static_key, connection, buffer: +'', ck: nil)
          @actor = actor
          @session = session
          @static_key = static_key
          @connection = connection
          @buffer = buffer
          @ck = ck
        end

        def encrypt_internal(data)
          n = @connection.protocol.cipher_state_encrypt.n
          k = @connection.protocol.cipher_state_encrypt.k
          ck = @connection.protocol.ck
          ciphertext = @connection.encrypt(data)
          if n == 999
            ck, k = @connection.protocol.hkdf_fn.call(ck, k, 2)
            @connection.protocol.ck = ck
            @connection.protocol.cipher_state_encrypt.initialize_key(k)
          end
          ciphertext
        end

        def encrypt(data)
          ciphertext = encrypt_internal([data.bytesize].pack('n*'))
          ciphertext + encrypt_internal(data)
        end

        def decrypt_internal(data)
          n = @connection.protocol.cipher_state_decrypt.n
          k = @connection.protocol.cipher_state_decrypt.k
          ck = @connection.protocol.ck
          plaintext = @connection.decrypt(data)
          if n == 999
            ck, k = @connection.protocol.hkdf_fn.call(ck, k, 2)
            @connection.protocol.ck = ck
            @connection.protocol.cipher_state_decrypt.initialize_key(k)
          end
          plaintext
        end

        def decrypt(buffer)
          if buffer.bytesize < 18
            [nil, buffer]
          else
            cipher_length = buffer[0...18]
            remainder = buffer[18..-1]
            plain_length = decrypt_internal(cipher_length)
            length = plain_length.unpack('n*').first
            if remainder.bytesize < length + 16
              [nil, buffer]
            else
              ciphertext = remainder[0...length + 16]
              remainder = remainder[length + 16..-1]
              payload = decrypt_internal(ciphertext)
              log(Logger::DEBUG, '/transport', "RECEIVE_DATA #{payload.bth}")
              message = Lightning::Wire::LightningMessages::LightningMessage.load(payload)
              [message, remainder]
            end
          end
        end

        def send_to(listener, message)
          log(Logger::INFO, '/transport', "RECEIVE #{message.inspect}")
          listener << message
        end

        def decrypt_and_send(buffer, listener)
          return +'' if buffer.nil? || buffer.empty?
          begin
            lightning_message, remainder = decrypt(buffer)
            send_to(listener, lightning_message) if lightning_message
            buffer = remainder || +''
          end while lightning_message && !buffer.empty?
          buffer
        end
      end

      class TransportHandlerStateHandshake < TransportHandlerState
        def expected_length(connection)
          case connection.protocol.handshake_state.message_patterns.length
          when 1 then 66
          when 2, 3 then 50
          end
        end

        def next(message)
          match message, (on Received.(~any) do |data|
            @buffer += data
            if @buffer.bytesize < expected_length(@connection)
              self
            else
              raise InvalidTransportVersion.new(@buffer[0], PREFIX) unless @buffer[0] == PREFIX
              payload = @buffer[1...expected_length(@connection)]
              remainder = @buffer[expected_length(@connection)..-1]
              _ = @connection.read_message(payload)

              unless @connection.handshake_finished
                payload = @connection.write_message('')
                @actor.reference.parent << Act[PREFIX + payload, @session]
              end

              @buffer = remainder

              if @connection.handshake_finished
                rs = @connection.protocol.keypairs[:rs][1]
                @actor.reference.parent << HandshakeCompleted[@session, @actor.reference, @static_key, rs.bth]
                TransportHandlerStateWaitingForListener.new(@actor, @session, @static_key, @connection, buffer: @buffer)
              else
                self
              end
            end
          end)
        end
      end

      class TransportHandlerStateWaitingForListener < TransportHandlerState
        def next(message)
          case message
          when Received
            @buffer += message[:data]
            self
          when Listener
            @buffer = decrypt_and_send(@buffer, message[:listener])
            TransportHandlerStateWaitingForCiphertext.new(@actor, @session, @static_key, @connection, buffer: @buffer, listener: message[:listener])
          end
        end
      end

      class TransportHandlerStateWaitingForCiphertext < TransportHandlerState
        def initialize(actor, session, static_key, connection, buffer: +'', listener: nil)
          super(actor, session, static_key, connection, buffer: buffer)
          @listener = listener
        end

        def next(message)
          case message
          when Received
            @buffer += message[:data]
            @buffer = decrypt_and_send(@buffer, @listener)
          when Lightning::Wire::LightningMessages
            ciphertext = encrypt(message.to_payload)
            log(Logger::DEBUG, '/transport', "SEND_DATA #{message.to_payload.bth}")
            log(Logger::INFO, '/transport', "SEND #{message.inspect}")
            @session << Send[ciphertext]
          end
          self
        end
      end
    end
  end
end
