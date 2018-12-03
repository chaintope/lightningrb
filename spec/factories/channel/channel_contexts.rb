# frozen_string_literal: true

FactoryBot.define do
  factory(:channel_context, class: 'Lightning::Channel::ChannelContext') do
    context { build(:context) }
    transport { spawn_dummy_actor }
    forwarder { spawn_dummy_actor }
    remote_node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    initialize_with { new(context, transport, forwarder, remote_node_id) }
  end
end
