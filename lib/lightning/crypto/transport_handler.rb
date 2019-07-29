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
              reference.parent << Act[PREFIX + payload, session]
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
        keypairs = { s: @static_key.htb, e: create_ephemeral_private_key.htb, rs: @remote_key.htb }
        initiator = Noise::Connection::Initiator.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        initiator.prologue = PROLOGUE
        initiator
      end

      def make_reader
        keypairs = { s: @static_key.htb, e: create_ephemeral_private_key.htb }
        responder = Noise::Connection::Responder.new('Noise_XK_secp256k1_ChaChaPoly_SHA256', keypairs: keypairs)
        responder.prologue = PROLOGUE
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

        def initialize(actor, session, static_key, connection, buffer: +'', length: 0)
          @actor = actor
          @session = session
          @static_key = static_key
          @connection = connection
          @buffer = buffer
          @length = length
        end

        def encrypt_internal(data)
          n = @connection.cipher_state_encrypt.n
          ciphertext = @connection.encrypt(data)
          @connection.rekey(@connection.cipher_state_encrypt) if n == 999
          ciphertext
        end

        def encrypt(data)
          ciphertext = encrypt_internal([data.bytesize].pack('n*'))
          ciphertext + encrypt_internal(data)
        end

        def decrypt_internal(data)
          n = @connection.cipher_state_decrypt.n
          plaintext = @connection.decrypt(data)
          @connection.rekey(@connection.cipher_state_decrypt) if n == 999
          plaintext
        end

        def decrypt(buffer, length)
          return [nil, 0, buffer] if buffer.bytesize < 18

          cipher_length = buffer[0...18]
          remainder = buffer[18..-1]

          if length.zero?
            plain_length = decrypt_internal(cipher_length)
            length = plain_length.unpack('n*').first
          end

          return [nil, length, buffer] if remainder.bytesize < length + 16

          ciphertext = remainder[0...length + 16]
          remainder = remainder[length + 16..-1]
          payload = decrypt_internal(ciphertext)
          message = Lightning::Wire::LightningMessages::LightningMessage.load(payload)
          [message, 0, remainder]
        end

        def send_to(listener, message)
          log(Logger::INFO, '/transport', "RECEIVE #{message.inspect}") unless message.is_a? Lightning::Wire::LightningMessages::GossipQuery
          listener << message
        end

        def decrypt_and_send(buffer, length, listener)
          return [+'', length] if buffer.nil? || buffer.empty?
          begin
            lightning_message, length, remainder = decrypt(buffer, length)
            send_to(listener, lightning_message) if lightning_message
            buffer = remainder || +''
          end while lightning_message && !buffer.empty?
          [buffer, length]
        end
      end

      class TransportHandlerStateHandshake < TransportHandlerState
        def expected_length(connection)
          case connection.handshake_state.message_patterns.length
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
                rs = @connection.rs
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
            @buffer, @length = decrypt_and_send(@buffer, @length, message[:listener])
            TransportHandlerStateWaitingForCiphertext.new(
              @actor, @session, @static_key, @connection, buffer: @buffer, length: @length, listener: message[:listener]
            )
          end
        end
      end

      class TransportHandlerStateWaitingForCiphertext < TransportHandlerState
        def initialize(actor, session, static_key, connection, buffer: +'', length: 0, listener: nil)
          super(actor, session, static_key, connection, buffer: buffer, length: length)
          @listener = listener
        end

        def next(message)
          case message
          when Received
            @buffer += message[:data]
            @buffer, @length = decrypt_and_send(@buffer, @length, @listener)
          when Lightning::Wire::LightningMessages
            ciphertext = encrypt(message.to_payload)
            log(Logger::INFO, '/transport', "SEND #{message.inspect}") unless message.is_a? Lightning::Wire::LightningMessages::GossipQuery
            @session << Send[ciphertext]
          end
          self
        end
      end
    end
  end
end

module Noise
  module Connection
    class Base
      def rekey(cipher)
        k = cipher.k
        @ck, k = protocol.hkdf_fn.call(@ck, k, 2)
        cipher.initialize_key(k)
      end

      def handshake_done(_c1, _c2)
        @handshake_hash = @symmetric_state.handshake_hash
        @s = @handshake_state.s
        @rs = @handshake_state.rs
        @ck = @handshake_state.symmetric_state.ck
        @handshake_state = nil
        @symmetric_state = nil
        @cipher_state_handshake = nil
      end
    end
  end
end
