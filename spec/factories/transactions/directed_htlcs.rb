# frozen_string_literal: true

FactoryBot.define do
  factory(:directed_htlc, class: 'FactoryBotWrapper') do
    direction 0 # 0: offered, 1: received
    add { build(:update_add_htlc).get }

    initialize_with do
      new(Lightning::Transactions::DirectedHtlc[direction, add])
    end

    trait :offered do
      direction { Lightning::Transactions::CommitmentSpec::OFFER }
    end

    trait :received do
      direction { Lightning::Transactions::CommitmentSpec::RECEIVE }
    end
  end
end
