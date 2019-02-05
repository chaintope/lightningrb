# frozen_string_literal: true

FactoryBot.define do
  factory(:waiting_for_revocation, class: 'FactoryBotWrapper') do
    next_remote_commit { build(:remote_commit, :has_received_htlcs).get }
    sent { build(:commitment_signed) }
    sent_after_local_commit_index { 1 }
    re_sign_asap { true }
    initialize_with do
      new(Lightning::Channel::Messages::WaitingForRevocation[
        next_remote_commit,
        sent,
        sent_after_local_commit_index,
        re_sign_asap
      ])
    end
  end
end
