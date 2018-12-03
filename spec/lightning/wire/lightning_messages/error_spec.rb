# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Error do
  let(:channel_id) { '2222222222222222222222222222222222222222222222222222222222222222' }
  let(:len) { 5 }
  let(:data) { '123456789a' }

  describe '#load' do
    subject { described_class.load(payload) }

    let(:payload) { '001122222222222222222222222222222222222222222222222222222222222222220005123456789a'.htb }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:len]).to eq len }
    it { expect(subject[:data]).to eq data }

    context 'short length - 1' do
      let(:payload) { '001122222222222222222222222222222222222222222222222222222222222222220001'.htb }

      it { is_expected.to eq nil }
    end
  end

  describe '#to_payload' do
    subject { described_class[channel_id, len, data].to_payload.bth }

    it { is_expected.to eq '001122222222222222222222222222222222222222222222222222222222222222220005123456789a' }
  end
end
