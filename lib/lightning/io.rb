# frozen_string_literal: true

module Lightning
  module IO
    autoload :Authenticator, 'lightning/io/authenticator'
    autoload :AuthenticateMessages, 'lightning/io/authenticator'
    autoload :Broadcast, 'lightning/io/broadcast'
    autoload :ClientSession, 'lightning/io/client'
    autoload :ClientConnection, 'lightning/io/client'
    autoload :Peer, 'lightning/io/peer'
    autoload :PeerEvents, 'lightning/io/peer_events'
    autoload :Server, 'lightning/io/server'
    autoload :ServerSession, 'lightning/io/server'
    autoload :ServerConnection, 'lightning/io/server'
    autoload :Switchboard, 'lightning/io/switchboard'
  end

  module Io
    autoload :Events, 'lightning/io/events'
  end
end
