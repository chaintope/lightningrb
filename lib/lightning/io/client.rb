# frozen_string_literal: true

module Lightning
  module IO
    class ClientSession < Concurrent::Actor::Context
      def self.connect(host, port, authenticator, static_key, remote_key)
        spawn(:client, authenticator, static_key, remote_key).tap do |me|
          EM.connect(host, port, ClientConnection, host, port, me)
        end
      end

      def initialize(authenticator, static_key, remote_key)
        @status = ClientStateDisconnect.new(nil, authenticator, static_key, remote_key)
      end

      def on_message(message)
        log(Logger::DEBUG, "#on_message #{@status} #{message}")
        @status = @status.next(self.reference, message)
      end
    end

    class ClientState
      include Lightning::Wire::HandshakeMessages
      include Lightning::IO::AuthenticateMessages

      attr_reader :conn, :authenticator, :static_key, :remote_key

      def initialize(conn, authenticator, static_key, remote_key)
        @authenticator = authenticator
        @static_key = static_key
        @remote_key = remote_key
        @conn = conn
      end
    end

    class ClientStateDisconnect < ClientState
      def next(actor, message)
        case message
        when Connected
          authenticator << PendingAuth[actor, static_key, remote_key: remote_key]
          ClientStateConnect.new(message[:conn], authenticator, static_key, remote_key)
        when Disconnected
          authenticator << Disconnected[Algebrick::None, Algebrick::None]
          self
        end
      end
    end

    class ClientStateConnect < ClientState
      def next(actor, message)
        case message
        when :close
          conn&.close_connection
          self
        when Lightning::Crypto::TransportHandler
          @transport = message.reference
          self
        when Received
          @transport << message if @transport
          self
        when Send
          conn&.send_data(message[:ciphertext])
          self
        when Disconnected
          authenticator << Disconnected[@transport, remote_key]
          ClientStateDisconnect.new(conn, authenticator, static_key, remote_key)
        else
          self
        end
      end
    end

    class ClientConnection < EM::Connection
      include Concurrent::Concern::Logging
      include Lightning::Wire::HandshakeMessages

      attr_accessor :host, :port

      def initialize(host, port, client)
        @client = client
        @host = host
        @port = port
      end

      def post_init
        log(Logger::DEBUG, '/client', 'post_init')
      end

      def connection_completed
        log(Logger::DEBUG, '/client', 'connection_completed')
        @client << Connected[self]
      end

      def receive_data(data)
        log(Logger::INFO, '/client', "receive_data #{data.bth}")
        @client << Received[data]
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, '/client', "unbind #{reason}")
        @client << Disconnected[Algebrick::None, Algebrick::None]
      end

      def inspect
        'Lightning::IO::ClientConnection'
      end
    end
  end
end
