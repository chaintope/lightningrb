# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::ChannelReestablish do
  let(:channel_id) { 'ab3d87b952e36f0aa7631c30e8dc0bcb3a28451700d2c8a39af5565a55845a48' }
  let(:next_local_commitment_number) { 242_842 }
  let(:next_remote_revocation_number) { 42 }

  let(:payload) do
    '0088ab3d87b952e36f0aa7631c30e8dc0bcb3a28451700d2c8a39af5565a5584' \
    '5a48000000000003b49a000000000000002a'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.next_local_commitment_number).to eq next_local_commitment_number }
    it { expect(subject.next_remote_revocation_number).to eq next_remote_revocation_number }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        next_local_commitment_number: next_local_commitment_number,
        next_remote_revocation_number: next_remote_revocation_number
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
