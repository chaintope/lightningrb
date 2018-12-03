# frozen_string_literal: true

module Lightning
  module Crypto
    class TransportHandler < Concurrent::Actor::Context
      include Lightning::Wire::HandshakeMessages

      PREFIX = '00'.htb.freeze
      PROLOGUE = '6c696768746e696e67'.htb.freeze

      attr_reader :static_key, :remote_key

      def initialize(static_key, conn, remote_key: nil)
        @static_key = static_key
        @remote_key = remote_key

        @connection =
          if initiator?
            make_writer.tap(&:start_handshake).tap do |connection|
              payload = connection.write_message('')
              reference.parent << Act[PREFIX + payload, conn]
            end
          else
            make_reader.tap(&:start_handshake)
          end
        @status = TransportHandlerStateHandshake.new(self, @static_key, @connection)
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

        def initialize(actor, static_key, connection, buffer: +'', ck: nil)
          @actor = actor
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
              type = payload[0...2].unpack('n*').first
              message_type = Lightning::Wire::LightningMessages.parse_message_type(type)
              return [nil, remainder] unless message_type
              [message_type.load(payload), remainder]
            end
          end
        end

        def send_to(listener, message)
          listener << message
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
          match message, (on Received.(~any, ~any) do |data, conn|
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
                @actor.reference.parent << Act[PREFIX + payload, conn]
              end

              @buffer = remainder

              if @connection.handshake_finished
                rs = @connection.protocol.keypairs[:rs][1]
                @actor.reference.parent << HandshakeCompleted[conn, @actor.reference, @static_key, rs.bth]
                TransportHandlerStateWaitingForListener.new(@actor, @static_key, @connection, buffer: @buffer)
              else
                self
              end
            end
          end)
        end
      end

      class TransportHandlerStateWaitingForListener < TransportHandlerState
        def next(message)
          match message, (on Received.(~any, any) do |data|
            @buffer += data
            self
          end), (on Listener.(~any, ~any) do |listener, conn|
            lightning_message, remainder = decrypt(@buffer) unless @buffer.empty?
            send_to(listener, lightning_message) if lightning_message
            @buffer = remainder || +''
            TransportHandlerStateWaitingForCiphertext.new(@actor, @static_key, @connection, buffer: @buffer, listener: listener, conn: conn)
          end)
        end
      end

      class TransportHandlerStateWaitingForCiphertext < TransportHandlerState
        def initialize(actor, static_key, connection, buffer: +'', listener: nil, conn: nil)
          super(actor, static_key, connection, buffer: buffer)
          @conn = conn
          @listener = listener
        end

        def next(message)
          match message, (on Received.(~any, any) do |data|
            @buffer += data
            lightning_message, remainder = decrypt(@buffer)
            send_to(@listener, lightning_message) if lightning_message
            @buffer = remainder || +''
          end), (on ~LightningMessage do |msg|
            ciphertext = encrypt(msg.to_payload)
            log(Logger::DEBUG, '/transport', "SEND_DATA #{msg.to_payload.bth}")
            @conn&.send_data(ciphertext)
          end)
          self
        end
      end
    end
  end
end
