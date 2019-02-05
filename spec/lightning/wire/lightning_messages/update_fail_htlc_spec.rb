# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::UpdateFailHtlc do
  let(:channel_id) { '98dca617a33effab8d34011d8f623997f5007ea805f2b1b8a0da23f84fc94dca' }
  let(:id) { 2 }
  let(:reason) { 'Time out htlc.' }
  let(:payload) do
    '008398dca617a33effab8d34011d8f623997f5007ea805f2b1b8a0da23f84fc9' \
    '4dca0000000000000002000e54696d65206f75742068746c632e'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.id).to eq id }
    it { expect(subject.reason).to eq reason }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        id: id,
        reason: reason
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
