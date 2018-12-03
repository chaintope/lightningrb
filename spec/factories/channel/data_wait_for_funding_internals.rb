# frozen_string_literal: true

FactoryBot.define do
  factory(:data_wait_for_funding_internal, class: 'FactoryBotWrapper') do
    temporary_channel_id '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357'
    local_param { build(:local_param).get }
    remote_param { build(:remote_param).get }
    funding_satoshis 10_000_000
    push_msat 4
    initial_feerate_per_kw 15000
    remote_first_per_commitment_point { build(:remote_first_per_commitment_point) }
    last_sent { build(:open_channel).get }

    initialize_with do
      new(Lightning::Channel::Messages::DataWaitForFundingInternal[
        temporary_channel_id,
        local_param,
        remote_param,
        funding_satoshis,
        push_msat,
        initial_feerate_per_kw,
        remote_first_per_commitment_point,
        last_sent
      ])
    end
  end
end
