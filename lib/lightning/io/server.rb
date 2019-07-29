# frozen_string_literal: true

module Lightning
  module IO
    class Server
      def self.start(host, port, authenticator, static_key)
        EM.run { EM.start_server(host, port, ServerConnection, self, authenticator, static_key) }
      end
    end

    class ServerSession < Concurrent::Actor::Context
      include Concurrent::Concern::Logging
      include Lightning::Wire::HandshakeMessages
      include Lightning::IO::AuthenticateMessages

      attr_reader :authenticator

      def initialize(conn, authenticator, static_key)
        @conn = conn
        @authenticator = authenticator
        @static_key = static_key
      end

      def on_message(message)
        case message
        when :close
          @conn&.close_connection
        when Connected
          authenticator << PendingAuth[self.reference, @static_key, {}]
        when Lightning::Crypto::TransportHandler
          @transport = message.reference
        when Received
          @transport << message if @transport
        when Send
          @conn&.send_data(message[:ciphertext])
        when Disconnected
          transport = @transport.nil? ? Algebrick::None : @transport
          authenticator << Disconnected[transport, Algebrick::None]
        end
      end
    end

    class ServerConnection < EM::Connection
      include Concurrent::Concern::Logging
      include Lightning::Wire::HandshakeMessages

      def initialize(server, authenticator, static_key)
        @server = server
        @static_key = static_key
        @authenticator = authenticator
      end

      def post_init
        log(Logger::DEBUG, '/server', 'post_init')
        @server_session = ServerSession.spawn(:server_session, self, @authenticator, @static_key)
        @server_session << Connected[self]
      end

      def connection_completed
        log(Logger::DEBUG, '/server', 'connection_completed')
      end

      def receive_data(data)
        log(Logger::DEBUG, '/server', "receive_data #{data.bth}")
        @server_session << Received[data] if @server_session
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, '/server', "unbind #{reason}")
        @server_session << Disconnected[Algebrick::None, Algebrick::None] if @server_session
      end

      def inspect
        'Lightning::IO::ServerConnection'
      end
    end
  end
end
