# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::RevokeAndAck do
  let(:channel_id) { '184b2cff6dfdc040767c06eb9d40a9bea44586a86b14ee5f79a118ce7ada4c58' }
  let(:per_commitment_secret) { '0000000000000000000000000000000000000000000000000000000000000000' }
  let(:next_per_commitment_point) { '031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f' }
  let(:payload) do
    '0085184b2cff6dfdc040767c06eb9d40a9bea44586a86b14ee5f79a118ce7ada' \
    '4c58000000000000000000000000000000000000000000000000000000000000' \
    '0000031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5' \
    'dd078f'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:per_commitment_secret]).to eq per_commitment_secret }
    it { expect(subject[:next_per_commitment_point]).to eq next_per_commitment_point }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        per_commitment_secret,
        next_per_commitment_point
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
