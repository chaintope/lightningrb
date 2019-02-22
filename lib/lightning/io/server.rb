# frozen_string_literal: true

module Lightning
  module IO
    class Server < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Wire::HandshakeMessages
      include Lightning::IO::AuthenticateMessages

      def self.start(host, port, authenticator, static_key)
        spawn(:server, authenticator, static_key).tap do |me|
          EM.start_server(host, port, ServerConnection, me, static_key)
        end
      end

      def initialize(authenticator, static_key)
        @authenticator = authenticator
        @static_key = static_key
      end

      def on_message(message)
        match message, (on Connected.(~any) do |conn|
          @authenticator << PendingAuth[conn, @static_key, {}]
        end)
      end
    end

    class ServerConnection < EM::Connection
      include Concurrent::Concern::Logging
      include Lightning::Wire::HandshakeMessages

      attr_accessor :transport

      def initialize(server, static_key)
        @server = server
        @static_key = static_key
      end

      def post_init
        log(Logger::DEBUG, '/server', 'post_init')
        @server << Connected[self]
      end

      def connection_completed
        log(Logger::DEBUG, '/server', 'connection_completed')
      end

      def receive_data(data)
        log(Logger::DEBUG, '/server', "receive_data #{data.bth}")
        operation = proc do
          transport << Received[data, self]
        end
        callback = proc { |result| }
        error_callback = proc do |e|
          log(Logger::DEBUG, '/server', "error #{e.message}")
          log(Logger::DEBUG, '/server', e.backtrace)
        end
        EM.defer(operation, callback, error_callback)
        log(Logger::INFO, '/server', "receive_data #{data.bth}")
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, '/server', "unbind #{reason}")
      end

      def inspect
        'Lightning::IO::ServerConnection'
      end
    end
  end
end
