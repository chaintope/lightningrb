# frozen_string_literal: true

FactoryBot.define do
  factory(:local_channel_update, class: 'FactoryBotWrapper') do
    channel { spawn_dummy_actor }
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    short_channel_id { 42 }
    remote_node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    channel_announcement { Algebrick::None }
    channel_update { build(:channel_update) }
    initialize_with do
      new(Lightning::Channel::Events::LocalChannelUpdate[
        channel, channel_id, short_channel_id, remote_node_id, channel_announcement, channel_update
      ])
    end
  end
end
