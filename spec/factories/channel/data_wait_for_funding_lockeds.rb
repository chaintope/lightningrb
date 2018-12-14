# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_funding_locked, class: 'FactoryBotWrapper') do
    commitments { build(:commitment).get }
    short_channel_id { 1 }
    last_sent { build(:funding_locked).get }

    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForFundingLocked[
        commitments,
        short_channel_id,
        last_sent
      ])
    end
  end
end
