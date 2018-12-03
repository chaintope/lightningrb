# frozen_string_literal: true

FactoryBot.define do
  factory(:utxo, class: 'Lightning::Transactions::Utxo') do
    value 10_000_000
    script_pubkey { Bitcoin::Script.parse_from_payload('0020c015c4a6be010e21657068fc2e6a9d02b27ebe4d490a25846f7237f104d1a3cd'.htb) }
    txid '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be'
    index 0
    redeem_script { Bitcoin::Script.new }
    initialize_with { new(value, script_pubkey, txid, index, redeem_script) }
    trait :multisig do
      script_pubkey { build(:script, :multisig_p2wsh) }
      redeem_script { build(:script, :multisig) }
    end
  end
end
