# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Blockchain::Wallet do
  let(:spv) { double('spv') }
  let(:wallet) { described_class.new(spv) }
  let(:ext_pubkey) { bitcoin_wallet.accounts.first.create_receive }
  let(:script_pubkey) { Bitcoin::Script.to_p2wpkh(ext_pubkey.hash160) }
  let(:txid) { '7aab993ae0f8679410032be197e2d7139669e0080f66f26a54f12cf05c1dfaff' }
  let(:utxo) { Lightning::Transactions::Utxo.new(1000, script_pubkey.to_payload.bth, txid, 0, nil) }
  let(:bitcoin_wallet) { create_test_wallet }

  before { spv.stub(:wallet).and_return(bitcoin_wallet) }
  after do
    wallet.utxo_db.clear
    bitcoin_wallet.close
  end

  describe '#complete' do
    subject { wallet.complete(tx) }

    let(:tx) do
      tx = Bitcoin::Tx.new
      tx.outputs << Bitcoin::TxOut.new(value: 1000, script_pubkey: script_pubkey)
      tx
    end

    context 'when exists a utxo whose value is same as tx output amount.' do
      before { wallet.add_utxo(txid, 0, 1000, script_pubkey.to_payload.bth, nil) }
      it do
        subject
        expect(tx.inputs.size).to eq 1
      end
    end

    context 'when multiple utxo is needed' do
      before do
        wallet.add_utxo(txid, 0, 600, script_pubkey.to_payload.bth, nil)
        wallet.add_utxo(txid, 1, 600, script_pubkey.to_payload.bth, nil)
        wallet.add_utxo(txid, 2, 600, script_pubkey.to_payload.bth, nil)
      end
      it do
        subject
        expect(tx.inputs.size).to eq 2
      end
    end

    context 'when insufficient fund.' do
      before do
        wallet.add_utxo(txid, 0, 999, script_pubkey.to_payload.bth, nil)
      end
      it do
        expect { subject }.to raise_error
      end
    end
  end

  describe '#add_utxo' do
    subject { wallet.add_utxo(txid, 0, 1000, script_pubkey.to_payload.bth, nil) }

    it { expect { subject }.to change { wallet.utxos.size }.from(0).to(1) }
  end

  describe '#remove_utxo' do
    subject { wallet.remove_utxo(txid, 0) }

    before { wallet.add_utxo(txid, 0, 1000, script_pubkey.to_payload.bth, nil) }

    it { expect { subject }.to change { wallet.utxos.size }.from(1).to(0) }
  end
end
