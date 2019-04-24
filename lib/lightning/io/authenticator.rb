# frozen_string_literal: true

module Lightning
  module IO
    module AuthenticateMessages
      AuthenticateMessage = Algebrick.type do
        variants  InitializingAuth = type { fields! switchboard: Switchboard },
                  PendingAuth = type { fields! session: Object, static_key: String, opt: Hash },
                  Authenticated = type { fields! session: Object, transport: Concurrent::Actor::Reference, remote_node_id: String },
                  Unauthenticated = type { fields! remote_node_id: type { variants Algebrick::None, String } }
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
          match message, (on ~PendingAuth.(~any, ~any, ~any) do |pending, session, static_key, opt|
            transport = Lightning::Crypto::TransportHandler.spawn(:transport, static_key, session, opt)
            @authenticating[transport] = pending
            self
          end), (on Act.(~any, ~any) do |data, session|
            session << Send[data]
            self
          end), (on HandshakeCompleted.(~any, ~any, ~any, ~any) do |session, transport, static_key, remote_key|
            pending = @authenticating[transport]
            if pending
              @authenticating.delete(transport)
              @switchboard << Authenticated[session, transport, remote_key]
            end
            self
          end), (on Disconnected.(~any, ~any) do |transport, remote_key|
            @authenticating.delete(transport) if @authenticating[transport]
            @switchboard << Unauthenticated[remote_key]
            self
          end)
        end
      end
    end
  end
end
