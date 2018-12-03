# frozen_string_literal: true

FactoryBot.define do
  factory(:script, class: 'Bitcoin::Script') do
    trait :multisig do
      initialize_with do
        Bitcoin::Script.to_multisig_script(2, [
          build(:key, :local_funding_pubkey).pubkey,
          build(:key, :remote_funding_pubkey).pubkey,
        ])
      end
    end
    trait :multisig_p2wsh do
      initialize_with do
        Bitcoin::Script.to_p2wsh(build(:script, :multisig))
      end
    end
  end
end
