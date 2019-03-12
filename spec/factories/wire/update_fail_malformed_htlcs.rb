# frozen_string_literal: true

FactoryBot.define do
  factory(:update_fail_malformed_htlc, class: 'Lightning::Wire::LightningMessages::UpdateFailMalformedHtlc') do
    channel_id { "00" * 32 }
    id { 0 }
    sha256_of_onion { "00" * 32 }
    failure_code { Lightning::Onion::FailureMessages::TYPES[:invalid_onion_hmac] }
  end
end
