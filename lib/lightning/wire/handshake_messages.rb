# frozen_string_literal: true

module Lightning
  module Wire
    module HandshakeMessages
      Algebrick.type do
        variants  Connected = type { fields! conn: Object },
                  Act = type { fields! data: String, conn: Object },
                  Received = type { fields! data: String, conn: Object },
                  HandshakeCompleted = type { fields! conn: Object, transport: Concurrent::Actor::Reference, static_key: String, remote_key: String },
                  Listener = type { fields! listener: Object, conn: Object },
                  Send = type { fields! ciphertext: String },
                  Disconnected = type { fields! conn: Object }
      end

      module Act
        def to_s
          "Act:#{[data.bth, conn]}"
        end
      end
      module Received
        def to_s
          "Received:#{[data.bth, conn]}"
        end
      end
    end
  end
end
