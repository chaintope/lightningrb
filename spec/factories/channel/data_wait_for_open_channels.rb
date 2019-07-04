# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_open_channel, class: 'FactoryBotWrapper') do
    init_fundee { build(:input_init_fundee).get }
    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForOpenChannel[init_fundee, ''])
    end
  end
end
