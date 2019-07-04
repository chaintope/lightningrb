# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_accept_channel, class: 'FactoryBotWrapper') do
    init_funder { build(:input_init_funder).get }
    last_sent { build(:open_channel) }
    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForAcceptChannel[
        init_funder, last_sent, ''
      ])
    end
  end
end
