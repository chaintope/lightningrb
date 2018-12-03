# frozen_string_literal: true

FactoryBot.define do
  factory(:context, class: 'Lightning::Context') do
    node_params { build(:node_param) }
    spv { create_test_spv }
    blockchain { spawn_dummy_actor }
    router { spawn_dummy_actor }
    broadcast { spawn_dummy_actor }
    register { spawn_dummy_actor }
    payment_handler { spawn_dummy_actor }
    wallet { double('wallet') }
    peer_db { Lightning::Store::PeerDb.new('tmp/test_peer_db') }
    node_db { Lightning::Store::NodeDb.new('tmp/test_node_db') }
    initialize_with { new(spv) }
  end
end
