# frozen_string_literal: true

module Lightning
  module Wire
    module HandshakeMessages
      Connected = Algebrick.type { fields! conn: Object }
      Act = Algebrick.type { fields! data: String, session: Concurrent::Actor::Reference }
      Received = Algebrick.type { fields! data: String }
      HandshakeCompleted = Algebrick.type do
        fields! session: Concurrent::Actor::Reference,
                transport: Concurrent::Actor::Reference,
                static_key: String,
                remote_key: String
      end
      Listener = Algebrick.type { fields! listener: Concurrent::Actor::Reference }
      Send = Algebrick.type { fields! ciphertext: String }
      Disconnected = Algebrick.type do
        fields! transport: type { variants Algebrick::None, Concurrent::Actor::Reference },
                remote_key: type { variants Algebrick::None, String }
      end


      module Act
        def to_s
          "Act:#{[data.bth, session]}"
        end
      end
      module Received
        def to_s
          "Received:#{[data.bth]}"
        end
      end
      module Send
        def to_s
          "Send:#{[ciphertext.bth]}"
        end
      end
    end
  end
end
