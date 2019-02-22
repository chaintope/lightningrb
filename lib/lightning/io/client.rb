# frozen_string_literal: true

module Lightning
  module IO
    class Client < Concurrent::Actor::Context
      def self.connect(host, port, authenticator, static_key, remote_key)
        spawn(:client, authenticator, static_key, remote_key).tap do |me|
          EM.connect(host, port, ClientConnection, host, port, me)
        end
      end

      def initialize(authenticator, static_key, remote_key)
        @status = ClientStateDisconnect.new(authenticator, static_key, remote_key)
      end

      def on_message(message)
        log(Logger::DEBUG, "#on_message #{@status} #{message}")
        @status = @status.next(message)
      end
    end

    class ClientState
      include Algebrick::Matching
      include Lightning::Wire::HandshakeMessages
      include Lightning::Wire::LightningMessages
      include Lightning::IO::AuthenticateMessages

      def initialize(authenticator, static_key, remote_key)
        @authenticator = authenticator
        @static_key = static_key
        @remote_key = remote_key
      end
    end

    class ClientStateDisconnect < ClientState
      def next(message)
        match message, (on Connected.(~any) do |conn|
          @authenticator << PendingAuth[conn, @static_key, remote_key: @remote_key]
          ClientStateConnect.new(@authenticator, @static_key, @remote_key)
        end)
      end
    end

    class ClientStateConnect < ClientState
      def next(_message)
        self
      end
    end

    class ClientConnection < EM::Connection
      include Concurrent::Concern::Logging
      include Lightning::Wire::HandshakeMessages

      attr_accessor :transport, :host, :port

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
        log(Logger::DEBUG, '/client', "receive_data #{data.bth}")
        operation = proc do
          transport << Received[data, self]
        end
        callback = proc { |result| }
        error_callback = proc do |e|
          log(Logger::DEBUG, '/server', "error #{e.message}")
          log(Logger::DEBUG, '/server', e.backtrace)
        end
        EM.defer(operation, callback, error_callback)
        log(Logger::INFO, '/client', "receive_data #{data.bth}")
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, '/client', "unbind #{reason}")
      end

      def inspect
        'Lightning::IO::ClientConnection'
      end
    end
  end
end
