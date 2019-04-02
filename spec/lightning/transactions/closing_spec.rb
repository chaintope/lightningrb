# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::Closing do
  let(:first_per_commitment_point) do
    '03f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a'
  end
  let(:channel_flags) { 0 }
  let(:minimum_depth) { 2 }
  let(:node_params) { Lightning::NodeParams.new }
  let(:default_final_script_pubkey) do
    '0000000000000000000000000000000000000000000000000000000000000000'
  end

  let(:local_spec) { build(:commitment_spec, :local).get }
  let(:remote_spec) { build(:commitment_spec, :remote).get }
  let(:script_pubkey) do
    hash = Bitcoin.hash160(default_final_script_pubkey.htb)
    Bitcoin::Script.to_p2wpkh(hash)
  end
  let(:utxo) { build(:utxo, :multisig) }

  let(:local_commit) do
    Lightning::Transactions::Commitment::LocalCommit[
      0,
      local_spec,
      Lightning::Channel::Messages::PublishableTxs[local_commit_tx, []]
    ]
  end
  let(:remote_commit) do
    Lightning::Transactions::Commitment::RemoteCommit[
      0,
      remote_spec,
      '11' * 32,
      first_per_commitment_point
    ]
  end
  let(:commit_tx) do
    Bitcoin::Tx.parse_from_payload(
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8002c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de84311054a56a00000000002200204adb4e2f00' \
      '643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e0400473044' \
      '022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319e518' \
      '5a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b1937' \
      'c383693901483045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c' \
      '0860c613173de7d39e7968022041376d520e9c0e1ad52248ddf4b22e12be8763' \
      '007df977253ef45a4ca3bdb7c001475221023da092f6980e58d2c037173180e9' \
      'a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66' \
      'd5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'.htb
    )
  end
  let(:local_commit_tx) do
    Lightning::Transactions::Commitment::TransactionWithUtxo[commit_tx, utxo]
  end
  let(:channel_id) { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
  let(:local_param) do
    build(
      :local_param,
      node_id: node_params.node_id,
      funding_priv_key: local_priv_key,
      default_final_script_pubkey: default_final_script_pubkey
    ).get
  end
  let(:remote_param) do
    build(
      :remote_param,
      node_id: node_params.node_id,
      funding_pubkey: remote_priv_key.pubkey
    ).get
  end
  let(:commitments) do
    Lightning::Channel::Messages::Commitments[
      local_param,
      remote_param,
      channel_flags,
      local_commit,
      remote_commit,
      build(:local_change).get,
      build(:remote_change).get,
      19,
      20,
      {},
      '',
      utxo,
      {},
      channel_id
    ]
  end
  let(:local_priv_key) { build(:key, :local_funding_privkey) }
  let(:remote_priv_key) { build(:key, :remote_funding_privkey) }
  let(:local_script_pubkey) { Bitcoin::Script.to_p2wpkh(Bitcoin.hash160(local_priv_key.pubkey)) }
  let(:remote_script_pubkey) { Bitcoin::Script.to_p2wpkh(Bitcoin.hash160(remote_priv_key.pubkey)) }
  let(:fee) { 0 }

  describe '.make_closing_tx' do
    subject(:closing_tx) do
      described_class.make_closing_tx(commitments, local_script_pubkey, remote_script_pubkey, fee)
    end

    it { expect(subject.tx.outputs.size).to eq 2 }
  end

  describe 'Each node offering a signature:' do
    subject(:closing_tx) do
      described_class.make_closing_tx(commitments, local_script_pubkey, remote_script_pubkey, fee)
    end

    describe 'MUST round each output down to whole satoshis.' do
      let(:local_spec) { build(:commitment_spec, :local, to_local_msat: 6_999_999_999, to_remote_msat: 3_000_000_001).get }
      let(:remote_spec) { build(:commitment_spec, :remote, to_local_msat: 3_000_000_001, to_remote_msat: 6_999_999_999).get }

      # to_remote
      it { expect(subject.tx.outputs[0].value).to eq 3_000_000 }
      it { expect(subject.tx.outputs[0].script_pubkey.to_s).to eq remote_script_pubkey.to_s }

      # to_local
      it { expect(subject.tx.outputs[1].value).to eq 6_999_999 }
      it { expect(subject.tx.outputs[1].script_pubkey.to_s).to eq local_script_pubkey.to_s }
    end

    describe 'MUST subtract the fee given by fee_satoshis from the output to the funder.' do
      let(:fee) { 10_000 }

      # to_remote
      it { expect(subject.tx.outputs[0].value).to eq 3_000_000 }
      # to_local
      it { expect(subject.tx.outputs[1].value).to eq 6_990_000 }
    end

    describe 'MUST remove any output below its own dust_limit_satoshis.' do
      let(:local_spec) { build(:commitment_spec, :local, to_local_msat: 9_999_454_000, to_remote_msat: 545_000).get }
      let(:remote_spec) { build(:commitment_spec, :remote, to_local_msat: 545_000, to_remote_msat: 9_999_454_000).get }

      it { expect(subject.tx.outputs.size).to eq 1 }
    end

    describe 'MAY eliminate its own output.' do
      let(:local_script_pubkey) { nil }

      it { expect(subject.tx.outputs.size).to eq 1 }
      # to_remote
      it { expect(subject.tx.outputs[0].value).to eq 3_000_000 }
      it { expect(subject.tx.outputs[0].script_pubkey.to_s).to eq remote_script_pubkey.to_s }
    end
  end

  # 02-peer-protocol.md#requirements-5
  describe '.valid_final_script_pubkey' do
    subject { described_class.valid_final_script_pubkey?(script_pubkey) }

    let(:script_pubkey) { '00000000000000000000' }

    it { is_expected.to be_falsy }
    describe 'MUST set scriptpubkey in one of the following forms:' do
      describe 'OP_DUP OP_HASH160 20 20-bytes OP_EQUALVERIFY OP_CHECKSIG (pay to pubkey hash), OR ' do
        let(:script_pubkey) { '76a9148911455a265235b2d356a1324af000d4dae0326288ac' }

        it { is_expected.to be_truthy }
      end

      describe 'OP_HASH160 20 20-bytes OP_EQUAL (pay to script hash), OR' do
        let(:script_pubkey) { 'a914e9c3dd0c07aac76179ebc76a6c78d4d67c6c160a87' }

        it { is_expected.to be_truthy }
      end

      describe 'OP_0 20 20-bytes (version 0 pay to witness pubkey), OR' do
        let(:script_pubkey) { '0014925d4028880bd0c9d68fbc7fc7dfee976698629c' }

        it { is_expected.to be_truthy }
      end

      describe 'OP_0 32 32-bytes (version 0 pay to witness script hash)' do
        let(:script_pubkey) { '00202db15af9e9bf2c0de55ab1935098229eb59389dc00b66b2828230b208ca767d7' }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.valid_signature?' do
    subject do
      described_class.valid_signature?(
        commitments,
        local_script_pubkey,
        remote_script_pubkey,
        remote_closing_fee,
        remote_closing_signature
      )
    end

    let(:remote_closing_fee) { 0 }
    let(:closing_tx) do
      Bitcoin::Tx.parse_from_payload(
        '0200000001bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b820b' \
        '584a4884890000000000ffffffff02c0c62d0000000000160014aa1df6627a20' \
        '234c9f04caf1ca67adb9254c3e15c0cf6a00000000001600141c60596620b0b9' \
        '966400cb710b8da6de5a80d68500000000'.htb
      )
    end
    let(:remote_closing_signature) do
      Lightning::Transactions.sign(closing_tx, commitments[:commit_input], remote_priv_key)
    end

    it { expect { subject }.not_to raise_error }

    context 'invalid close fee' do
      let(:remote_closing_fee) { 10861 }

      it { expect { subject }.to raise_error(Lightning::Exceptions::InvalidCloseFee) }
    end
  end
end
