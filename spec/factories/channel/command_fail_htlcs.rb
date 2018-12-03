# frozen_string_literal: true

FactoryBot.define do
  factory(:command_fail_htlc, class: 'FactoryBotWrapper') do
    id 0
    reason do
      Lightning::Onion::FailureMessages::PermanentChannelFailure
    end
    commit true
    initialize_with do
      new(Lightning::Channel::Messages::CommandFailHtlc[id, reason, commit])
    end
  end
end
