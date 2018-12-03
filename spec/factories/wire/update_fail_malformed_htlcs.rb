# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fail_malformed_htlc, class: 'FactoryBotWrapper') do
    channel_id { "00" * 32 }
    id 0
    sha256_of_onion ''
    failure_code { Lightning::Onion::FailureMessages::TYPES[:invalid_onion_hmac] }

    initialize_with do
      new(Lightning::Wire::LightningMessages::UpdateFailMalformedHtlc[
        channel_id, id, sha256_of_onion, failure_code
      ])
    end
  end
end
