# frozen_string_literal: true

FactoryBot.define do
  factory(:commitment_signed, class: 'Lightning::Wire::LightningMessages::CommitmentSigned') do
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    signature { build(:signature) }
    htlc_signature { [] }

    trait :has_htlcs do
      htlc_signature { ['99' * 32] }
    end

    trait :invalid do
      signature { build(:signature, :invalid) }
    end
  end
end
