# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::UpdateFee do
  let(:channel_id) { '92c2c3e833f0bd27d3c56c2e66c846f23b1d526d29d8dff306646360c9ad4a59' }
  let(:feerate_per_kw) { 2 }
  let(:payload) do
    '008692c2c3e833f0bd27d3c56c2e66c846f23b1d526d29d8dff306646360c9ad' \
    '4a5900000002'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.feerate_per_kw).to eq feerate_per_kw }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        feerate_per_kw: feerate_per_kw
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
