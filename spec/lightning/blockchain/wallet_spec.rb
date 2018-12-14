# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Blockchain::Wallet do
  let(:spv) { double('spv') }
  let(:context) { build(:context) }
  let(:wallet) { described_class.new(spv, context) }
  let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0000000000000000000000000000000000000000000000000000000000000000') }
  let(:txid) { '7aab993ae0f8679410032be197e2d7139669e0080f66f26a54f12cf05c1dfaff' }
  let(:utxos) do
    []
  end

  before do
    spv.stub(:list_unspent).and_return(utxos)
    spv.stub(:sign_transaction).and_return({
      'hex' => '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8002c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de84311054a56a00000000002200204adb4e2f00' \
      '643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e0400473044' \
      '022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319e518' \
      '5a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b1937' \
      'c383693901483045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c' \
      '0860c613173de7d39e7968022041376d520e9c0e1ad52248ddf4b22e12be8763' \
      '007df977253ef45a4ca3bdb7c001475221023da092f6980e58d2c037173180e9' \
      'a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66' \
      'd5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    })
    spv.stub(:generate_new_address).and_return('bc1qc7slrfxkknqcq2jevvvkdgvrt8080852dfjewde450xdlk4ugp7szw5tk9')
  end

  describe '#complete' do
    subject { wallet.complete(tx) }

    let(:tx) do
      tx = Bitcoin::Tx.new
      tx.outputs << Bitcoin::TxOut.new(value: 1000, script_pubkey: script_pubkey)
      tx
    end

    context 'when exists a utxo whose value is same as tx output amount.' do
      let(:utxos) do
        [{'txid' => txid, 'index' => 0, 'value' => 1000, 'script_pubkey' => script_pubkey.to_payload.bth}]
      end
      it do
        subject
        expect(tx.inputs.size).to eq 1
      end
    end

    context 'when multiple utxo is needed' do
      let(:utxos) do
        [
          {'txid' => txid, 'index' => 0, 'value' => 600, 'script_pubkey' => script_pubkey.to_payload.bth},
          {'txid' => txid, 'index' => 1, 'value' => 600, 'script_pubkey' => script_pubkey.to_payload.bth},
          {'txid' => txid, 'index' => 2, 'value' => 600, 'script_pubkey' => script_pubkey.to_payload.bth},
        ]
      end

      it do
        subject
        expect(tx.inputs.size).to eq 2
      end
    end

    context 'when insufficient fund.' do
      let(:utxos) do
        [
          {'txid' => txid, 'index' => 0, 'value' => 999, 'script_pubkey' => script_pubkey.to_payload.bth},
        ]
      end

      it do
        expect { subject }.to raise_error
      end
    end
  end
end
