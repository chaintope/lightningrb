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
      include Lightning::Wire::HandshakeMessages

      attr_reader :authenticator, :static_key, :remote_key

      def initialize(authenticator, static_key, remote_key)
        @authenticator = authenticator
        @static_key = static_key
        @remote_key = remote_key
      end
    end

    class ClientStateDisconnect < ClientState
      def next(message)
        case message
        when Connected
          authenticator << Lightning::IO::AuthenticateMessages::PendingAuth[message[:conn], static_key, remote_key: remote_key]
          ClientStateConnect.new(authenticator, static_key, remote_key)
        when Disconnected
          authenticator << Lightning::IO::AuthenticateMessages::Disconnected[message[:conn], remote_key]
          self
        end
      end
    end

    class ClientStateConnect < ClientState
      def next(message)
        case message
        when Disconnected
          authenticator << Lightning::IO::AuthenticateMessages::Disconnected[message[:conn], remote_key]
          ClientStateDisconnect.new(authenticator, static_key, remote_key)
        else
          self
        end
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
        log(Logger::INFO, '/client', "receive_data #{data.bth}")
        transport << Received[data, self]
      end

      def unbind(reason = nil)
        log(Logger::DEBUG, '/client', "unbind #{reason}")
        @client << Disconnected[self]
      end

      def inspect
        'Lightning::IO::ClientConnection'
      end
    end
  end
end
