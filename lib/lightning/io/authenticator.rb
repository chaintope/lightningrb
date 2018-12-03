# frozen_string_literal: true

module Lightning
  module IO
    module AuthenticateMessages
      AuthenticateMessage = Algebrick.type do
        variants  InitializingAuth = type { fields! switchboard: Switchboard },
                  PendingAuth = type { fields! conn: Object, static_key: String, opt: Hash },
                  Authenticated = type { fields! conn: Object, transport: Concurrent::Actor::Reference, remote_node_id: String }
      end
    end

    class Authenticator < Concurrent::Actor::Context
      def initialize
        @status = AuthenticatorStateInit.new
      end

      def on_message(message)
        log(Logger::DEBUG, "#{message}:#{@status}")
        @status = @status.next(message)
      end

      class AuthenticatorState
        include Algebrick::Matching
        include Lightning::Wire::HandshakeMessages
        include Lightning::IO::AuthenticateMessages
      end

      class AuthenticatorStateInit < AuthenticatorState
        def next(message)
          match message, (on InitializingAuth.(~any) do |switchboard|
            AuthenticatorStateReady.new(switchboard)
          end)
        end
      end

      class AuthenticatorStateReady < AuthenticatorState
        def initialize(switchboard)
          @switchboard = switchboard
          @authenticating = {}
        end

        def next(message)
          match message, (on ~PendingAuth.(~any, ~any, ~any) do |pending, conn, static_key, opt|
            conn.transport = Lightning::Crypto::TransportHandler.spawn(
              :transport,
              static_key,
              conn,
              opt
            )

            @authenticating[static_key] = pending
            self
          end), (on Act.(~any, ~any) do |data, conn|
            conn&.send_data(data)
            self
          end), (on HandshakeCompleted.(~any, ~any, ~any, ~any) do |conn, transport, static_key, remote_key|
            pending = @authenticating[static_key]
            if pending
              @authenticating.delete(static_key)
              @switchboard << Authenticated[conn, transport, remote_key]
            end
            self
          end), (on Terminated.(~any, ~any) do |transport, static_key|
            pending = @authenticating[static_key]
            @authenticating.delete(static_key) if pending
            self
          end)
        end
      end
    end
  end
end
