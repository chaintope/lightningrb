# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::UpdateFailMalformedHtlc do
  let(:channel_id) { '649791dd689ebbc5ce25917606a98eaf383370d34e1fba6d52d55f5049be1014' }
  let(:id) { 2 }
  let(:sha256_of_onion) { '4740063e8efafa7bba194364307f15c7f63484562f675258ec8adef14e638a92' }
  let(:failure_code) { 1111 }
  let(:payload) do
    '0087649791dd689ebbc5ce25917606a98eaf383370d34e1fba6d52d55f5049be' \
    '101400000000000000024740063e8efafa7bba194364307f15c7f63484562f67' \
    '5258ec8adef14e638a920457'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.id).to eq id }
    it { expect(subject.sha256_of_onion).to eq sha256_of_onion }
    it { expect(subject.failure_code).to eq failure_code }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        id: id,
        sha256_of_onion: sha256_of_onion,
        failure_code: failure_code
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
