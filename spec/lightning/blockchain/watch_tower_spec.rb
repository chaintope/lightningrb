# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Blockchain::WatchTower do
  let(:spv) { create_test_spv }
  let(:ln_context) { build(:context, spv: spv) }
  let(:watch_tower) { described_class.spawn(:watch_tower, ln_context) }

  describe 'on_message' do
    context 'with Register' do
      subject { watch_tower << message}

      let(:message) { Lightning::Blockchain::WatchTower::Register.new(head_tx_hash: tx_hash[0...32], encrypted_payload: encrypted_payload) }
      let(:tx) { Bitcoin::Tx.new }
      let(:tx_hash) { tx.tx_hash }
      let(:encrypted_payload) do
        penalty_tx = Bitcoin::Tx.new.tap {|t| t.version = 2}
        cipher = RbNaCl::AEAD::ChaCha20Poly1305IETF.new(tx_hash.htb)
        cipher.encrypt("\x00" * 12, penalty_tx.to_payload, '').bth
      end

      it do
        expect { subject }.to change { watch_tower.ask!(:transactions).size }.by(1)
      end

      it do
        subject
        expect(watch_tower.ask!(:transactions)[tx_hash[0...32]]).to eq [[encrypted_payload, 0]]
      end
    end

    context 'with TxReceived' do
      subject do
        watch_tower << message
        watch_tower.ask(:await).wait
      end

      let(:message) { Bitcoin::Grpc::TxReceived.new(tx_hash: tx_hash, tx_payload: tx.to_payload.bth) }
      let(:tx) { Bitcoin::Tx.new }
      let(:tx_hash) { tx.tx_hash }
      let(:penalty_tx) { Bitcoin::Tx.new.tap {|t| t.lock_time = 0xffff0000} }
      let(:encrypted_payload) do
        cipher = RbNaCl::AEAD::ChaCha20Poly1305IETF.new(tx_hash.htb)
        cipher.encrypt("\x00" * 12, penalty_tx.to_payload, '').bth
      end

      before do
        watch_tower << Lightning::Blockchain::WatchTower::Register.new(head_tx_hash: tx_hash[0...32], encrypted_payload: encrypted_payload)
      end

      it do
        expect(spv).to receive(:broadcast).with(penalty_tx)
        expect { subject }.to change { watch_tower.ask!(:transactions).size }.by(-1)
      end

      context 'when invalid tx is in watch items' do
        before do
          watch_tower << Lightning::Blockchain::WatchTower::Register.new(head_tx_hash: tx_hash[0...32], encrypted_payload: invali_encrypted_payload)
        end

        let(:invalid_penalty_tx) { Bitcoin::Tx.new.tap {|t| t.lock_time = 0xffffffff} }

        let(:invali_encrypted_payload) do
          cipher = RbNaCl::AEAD::ChaCha20Poly1305IETF.new(tx_hash[0...32].htb + "\x00" * 16)
          cipher.encrypt("\x00" * 12, invalid_penalty_tx.to_payload, '').bth
        end

        it 'broadast valid penalty tx only' do
          expect(spv).to receive(:broadcast).with(penalty_tx)
          expect(spv).not_to receive(:broadcast).with(invalid_penalty_tx)
          expect { subject }.not_to change { watch_tower.ask!(:transactions).size }
        end
      end
    end
  end
end