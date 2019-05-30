# frozen_string_literal: true

FactoryBot.define do
  factory(:remote_change, class: 'FactoryBotWrapper') do
    proposed { [] }
    acked { [] }
    signed { [] }
    initialize_with do
      new(Lightning::Channel::Messages::RemoteChanges[proposed, acked, signed])
    end

    trait :has_remote_change do
      proposed { [ build(:update_add_htlc) ] }
    end

    trait :has_fulfill do
      proposed { [ build(:update_add_htlc), build(:update_fulfill_htlc)] }
    end
  end
end
