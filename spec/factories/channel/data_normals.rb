# frozen_string_literal: true

FactoryBot.define do
  factory(:data_normal, class: 'FactoryBotWrapper') do
    commitments { build(:commitment).get }
    short_channel_id 1
    buried 0
    channel_announcement Algebrick::None
    channel_update { build(:channel_update).get }
    local_shutdown Algebrick::None
    remote_shutdown Algebrick::None
    initialize_with do
      new(Lightning::Channel::Messages::DataNormal[
        commitments,
        short_channel_id,
        buried,
        channel_announcement,
        channel_update,
        local_shutdown,
        remote_shutdown
      ])
    end
  end
end
