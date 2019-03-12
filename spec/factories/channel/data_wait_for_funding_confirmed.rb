# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_funding_confirmed, class: 'FactoryBotWrapper') do
    temporary_channel_id { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    commitments { build(:commitment).get }
    deferred { Algebrick::Some[Lightning::Wire::LightningMessages::FundingLocked][build(:funding_locked).get] }
    last_sent { build(:funding_created) }

    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForFundingConfirmed[
        temporary_channel_id,
        commitments,
        deferred,
        last_sent
      ])
    end
  end
end
