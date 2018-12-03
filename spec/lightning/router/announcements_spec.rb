# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::Announcements do
  describe '.make_channel_announcement' do
    let(:node_param) { build(:node_param) }
    let(:chain_hash) { node_param.chain_hash }
    let(:short_channel_id) { 1 }
    let(:local_node_secret) { '22' * 32 }
    let(:local_node_id) { Bitcoin::Key.new(priv_key: local_node_secret).pubkey } # 02466d7fcae563e5cb09a0d1870bb580344804617879a14949cf22285f1bae3f27
    let(:remote_node_secret) { '11' * 32 }
    let(:remote_node_id) { Bitcoin::Key.new(priv_key: remote_node_secret).pubkey } # 034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa
    let(:local_funding_private_key) { '33' * 32 }
    let(:local_funding_key) { Bitcoin::Key.new(priv_key: local_funding_private_key).pubkey }
    let(:remote_funding_private_key) { '44' * 32 }
    let(:remote_funding_key) { Bitcoin::Key.new(priv_key: remote_funding_private_key).pubkey }

    subject do
      local_node_signature, local_bitcoin_signature = described_class.channel_announcement_signature(
        chain_hash,
        short_channel_id,
        local_node_secret,
        remote_node_id,
        local_funding_private_key,
        remote_funding_key,
        ''
      )
      remote_node_signature, remote_bitcoin_signature = described_class.channel_announcement_signature(
        chain_hash,
        short_channel_id,
        remote_node_secret,
        local_node_id,
        remote_funding_private_key,
        local_funding_key,
        ''
      )
      described_class.make_channel_announcement(
        node_param.chain_hash,
        short_channel_id,
        local_node_id,
        remote_node_id,
        local_funding_key,
        remote_funding_key,
        local_node_signature,
        remote_node_signature,
        local_bitcoin_signature,
        remote_bitcoin_signature)
    end

    context 'local node id is lesser than remote one' do
      it { expect(subject.valid_signature?).to be_truthy }
      it { expect(subject[:chain_hash]).to eq chain_hash }
      it { expect(subject[:short_channel_id]).to eq short_channel_id }
      it { expect(subject[:node_id_1]).to eq local_node_id }
      it { expect(subject[:node_id_2]).to eq remote_node_id }
      it { expect(subject[:bitcoin_key_1]).to eq local_funding_key }
      it { expect(subject[:bitcoin_key_2]).to eq remote_funding_key }
    end

    context 'local node id is greater than remote one' do
      let(:local_node_secret) { '11' * 32 }
      let(:remote_node_secret) { '22' * 32 }

      it { expect(subject.valid_signature?).to be_truthy }
      it { expect(subject[:chain_hash]).to eq chain_hash }
      it { expect(subject[:short_channel_id]).to eq short_channel_id }
      it { expect(subject[:node_id_1]).to eq remote_node_id }
      it { expect(subject[:node_id_2]).to eq local_node_id }
      it { expect(subject[:bitcoin_key_1]).to eq remote_funding_key }
      it { expect(subject[:bitcoin_key_2]).to eq local_funding_key }
    end
  end

  describe '.make_node_announcement' do
    let(:node_secret) { '11' * 32 }
    let(:node_id) { Bitcoin::Key.new(priv_key: node_secret).pubkey }
    let(:node_rgb_color) { [255, 127, 0] }
    let(:node_alias) { 'Lightning Node' }
    let(:addresses) { [ '10.10.10.10:9735' ] }
    let(:timestamp) { 1536060934 }

    subject do
      described_class.make_node_announcement(
        node_secret,
        node_rgb_color,
        node_alias,
        addresses,
        timestamp
      )
    end

    it { expect(subject.valid_signature?).to be_truthy }
    it { expect(subject[:features]).to eq '' }
    it { expect(subject[:timestamp]).to eq timestamp }
    it { expect(subject[:node_id]).to eq node_id }
    it { expect(subject[:node_rgb_color]).to eq node_rgb_color }
    it { expect(subject[:node_alias]).to eq node_alias }
    it { expect(subject[:addresses]).to eq addresses }
  end

  describe '.make_channel_update' do
    let(:node_param) { build(:node_param) }
    let(:chain_hash) { node_param.chain_hash}
    let(:short_channel_id) { 1 }
    let(:local_node_secret) { '22' * 32 }
    let(:local_node_id) { Bitcoin::Key.new(priv_key: local_node_secret).pubkey }
    let(:remote_node_secret) { '11' * 32 }
    let(:remote_node_id) { Bitcoin::Key.new(priv_key: remote_node_secret).pubkey }
    let(:timestamp) { 1536060934 }
    let(:cltv_expiry_delta) { node_param.expiry_delta_blocks }
    let(:htlc_minimum_msat) { node_param.htlc_minimum_msat }
    let(:fee_base_msat) { node_param.fee_base_msat }
    let(:fee_proportional_millionths) { node_param.fee_proportional_millionths }

    subject do
      described_class.make_channel_update(
        chain_hash,
        local_node_secret,
        remote_node_id,
        short_channel_id,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths,
        timestamp: timestamp
      )
    end

    it { expect(subject.valid_signature?(local_node_id)).to be_truthy }
    it { expect(subject[:chain_hash]).to eq chain_hash }
    it { expect(subject[:short_channel_id]).to eq short_channel_id }
    it { expect(subject[:timestamp]).to eq timestamp }
    it { expect(subject[:message_flags]).to eq 0 }
    it { expect(subject[:channel_flags]).to eq 1 }
    it { expect(subject[:cltv_expiry_delta]).to eq cltv_expiry_delta }
    it { expect(subject[:htlc_minimum_msat]).to eq htlc_minimum_msat }
    it { expect(subject[:fee_base_msat]).to eq fee_base_msat }
    it { expect(subject[:fee_proportional_millionths]).to eq fee_proportional_millionths }
  end
end
