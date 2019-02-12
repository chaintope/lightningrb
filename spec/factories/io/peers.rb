# frozen_string_literal: true

FactoryBot.define do
  factory(:peer, class: 'Concurrent::Actor::Reference') do
    authenticator { spawn_dummy_actor(name: :authenticator) }
    context { build(:context) }
    remote_node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    initialize_with do
      Lightning::IO::Peer.spawn(:peer, authenticator, context, remote_node_id)
    end
  end
end
