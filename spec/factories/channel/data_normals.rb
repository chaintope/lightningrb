# frozen_string_literal: true

FactoryBot.define do
  factory(:data_normal, class: 'FactoryBotWrapper') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    commitments { build(:commitment).get }
    short_channel_id { 1 }
    buried { 0 }
    channel_announcement { Algebrick::None }
    channel_update { build(:channel_update) }
    local_shutdown { Algebrick::None }
    remote_shutdown { Algebrick::None }
    initialize_with do
      new(Lightning::Channel::Messages::DataNormal[
        temporary_channel_id,
        commitments,
        short_channel_id,
        buried,
        channel_announcement,
        channel_update,
        local_shutdown,
        remote_shutdown,
        ''
      ])
    end
  end
end
