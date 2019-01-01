# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::ChannelUpdate do
  let(:signature) do
    '304402203b5969880d01a90c34ea3999eb78e6bd476603db6bd0ba96742a3e60' \
    '0b0eaebc022000aa488c80e8e949452b471bc6d5f15e48bd10c8b4cb1c3f7e76' \
    'a55d68643725'
  end
  let(:chain_hash) { '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f' }
  let(:short_channel_id) { 1 }
  let(:timestamp) { 2 }
  let(:message_flags) { 192 }
  let(:channel_flags) { 128 }
  let(:cltv_expiry_delta) { 3 }
  let(:htlc_minimum_msat) { 4 }
  let(:fee_base_msat) { 5 }
  let(:fee_proportional_millionths) { 6 }

  let(:payload) do
    '01023b5969880d01a90c34ea3999eb78e6bd476603db6bd0ba96742a3e600b0e' \
    'aebc00aa488c80e8e949452b471bc6d5f15e48bd10c8b4cb1c3f7e76a55d6864' \
    '372506226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188' \
    '910f000000000000000100000002c08000030000000000000004000000050000' \
    '0006'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:signature]).to eq signature }
    it { expect(subject[:chain_hash]).to eq chain_hash }
    it { expect(subject[:short_channel_id]).to eq short_channel_id }
    it { expect(subject[:timestamp]).to eq timestamp }
    it { expect(subject[:message_flags]).to eq message_flags }
    it { expect(subject[:channel_flags]).to eq channel_flags }
    it { expect(subject[:cltv_expiry_delta]).to eq cltv_expiry_delta }
    it { expect(subject[:htlc_minimum_msat]).to eq htlc_minimum_msat }
    it { expect(subject[:fee_base_msat]).to eq fee_base_msat }
    it { expect(subject[:fee_proportional_millionths]).to eq fee_proportional_millionths }
  end

  describe '#to_payload' do
    subject do
      described_class[
        signature,
        chain_hash,
        short_channel_id,
        timestamp,
        message_flags,
        channel_flags,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe 'valid_signature?' do
    subject { msg.valid_signature?(node_id) }

    let(:msg) do
      described_class[
        signature,
        chain_hash,
        short_channel_id,
        timestamp,
        message_flags,
        channel_flags,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths
      ]
    end
    let(:node_id) { node_key.pubkey }
    let(:node_secret) { '11' * 32 }
    let(:node_key) { Bitcoin::Key.new(priv_key: node_secret) }
    let(:signature) do
      witness = described_class.witness(
        chain_hash,
        short_channel_id,
        timestamp,
        message_flags,
        channel_flags,
        cltv_expiry_delta,
        htlc_minimum_msat,
        fee_base_msat,
        fee_proportional_millionths
      )
      node_key.sign(witness).bth
    end
    let(:chain_hash) { '12' * 32 }
    let(:short_channel_id) { 1 }
    let(:timestamp) { 2 }
    let(:message_flags) { 3 }
    let(:channel_flags) { 4 }
    let(:cltv_expiry_delta) { 5 }
    let(:htlc_minimum_msat) { 6 }
    let(:fee_base_msat) { 7 }
    let(:fee_proportional_millionths) { 8 }

    it { expect(subject).to be_truthy }
  end
end
