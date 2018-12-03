# frozen_string_literal: true

module Lightning
  module IO
    autoload :Authenticator, 'lightning/io/authenticator'
    autoload :Broadcast, 'lightning/io/broadcast'
    autoload :Client, 'lightning/io/client'
    autoload :Peer, 'lightning/io/peer'
    autoload :PeerEvents, 'lightning/io/peer_events'
    autoload :Server, 'lightning/io/server'
    autoload :Switchboard, 'lightning/io/switchboard'
  end
end
