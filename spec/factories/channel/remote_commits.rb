# frozen_string_literal: true

FactoryBot.define do
  factory(:remote_commit, class: 'FactoryBotWrapper') do
    index 0
    spec { build(:commitment_spec, :remote).get }
    txid { '00' * 32 }
    remote_per_commitment_point { '00' * 33 }
    initialize_with do
      new(Lightning::Transactions::Commitment::RemoteCommit[
        index,
        spec,
        txid,
        remote_per_commitment_point
      ])
    end

    trait :has_offered_htlcs do
      spec { build(:commitment_spec, :has_offered_htlcs).get }
    end

    trait :has_received_htlcs do
      spec { build(:commitment_spec, :has_received_htlcs).get }
    end
  end
end
