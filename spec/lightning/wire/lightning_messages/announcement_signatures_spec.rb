# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::AnnouncementSignatures do
  let(:channel_id) { '44567bb5b1ad5fb71b3a9639f495a07fb0d6d1498865b6eb3aa21e104727c1d9' }
  let(:short_channel_id) { 42 }
  let(:node_signature) do
    '304402204b3f1207089f2473819d5a231cb3f507cb3bd9730063ad54f5a26255' \
    'de0f1bfd0220353ac520cbb32c4b183f443801947b576cafd44206fdf5f4b952' \
    '30834fe9ae1d'
  end
  let(:bitcoin_signature) do
    '3044022016424896c3dd3a784c177b10e9d0d59850de58aca55f475bff1de9ad' \
    '799e672202206b40ceb05d404aaca86dcfec30881d675061013bf605b2077f3b' \
    '1f1169d335d5'
  end
  let(:payload) do
    '010344567bb5b1ad5fb71b3a9639f495a07fb0d6d1498865b6eb3aa21e104727' \
    'c1d9000000000000002a4b3f1207089f2473819d5a231cb3f507cb3bd9730063' \
    'ad54f5a26255de0f1bfd353ac520cbb32c4b183f443801947b576cafd44206fd' \
    'f5f4b95230834fe9ae1d16424896c3dd3a784c177b10e9d0d59850de58aca55f' \
    '475bff1de9ad799e67226b40ceb05d404aaca86dcfec30881d675061013bf605' \
    'b2077f3b1f1169d335d5'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:short_channel_id]).to eq short_channel_id }
    it { expect(subject[:node_signature]).to eq node_signature }
    it { expect(subject[:bitcoin_signature]).to eq bitcoin_signature }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        short_channel_id,
        node_signature,
        bitcoin_signature
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
