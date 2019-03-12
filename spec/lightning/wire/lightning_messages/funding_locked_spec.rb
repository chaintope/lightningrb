# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::FundingLocked do
  let(:channel_id) { 'efcf55567d820d48621613a9198dfd7e0a0afd55ae1e69028d9fe0903ca20178' }
  let(:next_per_commitment_point) { '024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d0766' }
  let(:payload) do
    '0024efcf55567d820d48621613a9198dfd7e0a0afd55ae1e69028d9fe0' \
    '903ca20178024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac942' \
    '3374c451a7254d0766'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.next_per_commitment_point).to eq next_per_commitment_point }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        next_per_commitment_point: next_per_commitment_point,
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
