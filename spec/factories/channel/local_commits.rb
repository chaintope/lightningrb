# frozen_string_literal: true

FactoryBot.define do
  factory(:local_commit, class: 'FactoryBotWrapper') do
    index 0
    spec { build(:commitment_spec, :local).get }
    publishable_txs { build(:publishable_tx).get }
    initialize_with do
      new(Lightning::Transactions::Commitment::LocalCommit[index, spec, publishable_txs])
    end

    trait :has_received_htlcs do
      spec { build(:commitment_spec, :has_received_htlcs).get }
    end

    trait :has_offered_htlcs do
      spec { build(:commitment_spec, :has_offered_htlcs).get }
    end
  end
end
