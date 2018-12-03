# frozen_string_literal: true

FactoryBot.define do
  factory(:command_fail_malformed_htlc, class: 'FactoryBotWrapper') do
    id 0
    onion_hash { '11' * 32 }
    failure_code { Lightning::Onion::FailureMessages::TYPES[:invalid_onion_hmac] }
    commit true
    initialize_with do
      new(Lightning::Channel::Messages::CommandFailMalformedHtlc[
        id,
        onion_hash,
        failure_code,
        commit
      ])
    end
  end
end
