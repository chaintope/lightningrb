# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_funding_confirmed, class: 'FactoryBotWrapper') do
    commitments { build(:commitment).get }
    deferred { Algebrick::Some[Lightning::Wire::LightningMessages::FundingLocked][build(:funding_locked).get] }
    last_sent { build(:funding_created).get }

    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForFundingConfirmed[
        commitments,
        deferred,
        last_sent
      ])
    end
  end
end
