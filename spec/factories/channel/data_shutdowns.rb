# frozen_string_literal: true

FactoryBot.define do
  factory(:data_shutdown, class: 'FactoryBotWrapper') do
    commitments { build(:commitment).get }
    short_channel_id { 0 }
    local_shutdown { build(:shutdown) }
    remote_shutdown { build(:shutdown) }
    initialize_with do
      new(Lightning::Channel::Messages::DataShutdown[commitments, short_channel_id, local_shutdown, remote_shutdown])
    end
  end
end
