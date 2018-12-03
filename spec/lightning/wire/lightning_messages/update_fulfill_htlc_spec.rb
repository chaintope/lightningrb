# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::UpdateFulfillHtlc do
  let(:channel_id) { '1fdcd96a99b9bd8b7f0f6cd6f84468971414d2f964c0c2128ce2fd7f1f653e48' }
  let(:id) { 2 }
  let(:payment_preimage) { '0000000000000000000000000000000000000000000000000000000000000000' }
  let(:payload) do
    '00821fdcd96a99b9bd8b7f0f6cd6f84468971414d2f964c0c2128ce2fd7f1f65' \
    '3e48000000000000000200000000000000000000000000000000000000000000' \
    '00000000000000000000'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:id]).to eq id }
    it { expect(subject[:payment_preimage]).to eq payment_preimage }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        id,
        payment_preimage
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
