# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions do
  let(:obscured_commitment_transaction_number) { 0x2bb038521914 ^ 42 }
  let(:sequence) { 0x80000000 | (obscured_commitment_transaction_number >> 24) }
  let(:lock_time) { (obscured_commitment_transaction_number & 0xffffff) | 0x20000000 }
  let(:tx) do
    Bitcoin::Tx.new.tap do |tx|
      tx.version = 2
      tx.lock_time = lock_time
      out_point = Bitcoin::OutPoint.new('8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be'.htb.reverse.bth, 0)
      tx.inputs << Bitcoin::TxIn.new(out_point: out_point, sequence: sequence)
      script = Bitcoin::Script.to_p2wpkh(Bitcoin.hash160('0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b'))
      tx.outputs << Bitcoin::TxOut.new(value: 3_000_000, script_pubkey: script)
      script = Bitcoin::Script.parse_from_payload(
        '63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402' \
        'bf2b1967029000b2752103fd5960528dc152014952efdb702a88f71e3c1653b2' \
        '314431701ec77e57fde83c68ac'.htb
      )
      tx.outputs << Bitcoin::TxOut.new(value: 6_989_140, script_pubkey: Bitcoin::Script.to_p2wsh(script))
    end
  end
  let(:redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '5221023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe43' \
      '6f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3' \
      'c39fa711c152ae'.htb
    )
  end
  let(:utxo) do
    Lightning::Transactions::Utxo.new(
      10_000_000,
      Bitcoin::Script.to_p2wsh(redeem_script),
      '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be',
      0,
      redeem_script
    )
  end

  describe '.sign' do
    subject { described_class.sign(tx, utxo, local_key) }

    let(:local_key) { build(:key, :local_funding_privkey) }
    let(:expected) do
      '3044022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319' \
      'e5185a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b' \
      '1937c3836939'
    end

    it { is_expected.to eq expected }
  end

  describe '.add_sigs' do
    subject { described_class.add_sigs(tx, utxo, local_funding_pubkey, remote_funding_pubkey, local_sig_of_local_tx, remote_sig) }

    let(:local_funding_pubkey) { build(:key, :local_funding_pubkey).pubkey }
    let(:remote_funding_pubkey) { build(:key, :remote_funding_pubkey).pubkey }
    let(:local_sig_of_local_tx) do
      '3044022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319' \
      'e5185a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b' \
      '1937c3836939'
    end
    let(:remote_sig) do
      '3045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c0860c613173d' \
      'e7d39e7968022041376d520e9c0e1ad52248ddf4b22e12be8763007df977253e' \
      'f45a4ca3bdb7c0'
    end

    it { expect(subject.verify_input_sig(0, Bitcoin::Script.to_p2wsh(redeem_script), amount: 10_000_000)).to be_truthy }
  end
end
