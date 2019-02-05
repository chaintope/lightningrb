# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Pong do
  describe '#load' do
    subject { described_class.load(payload) }

    let(:payload) { '0013000a01010101010101010101'.htb }

    it { expect(subject[:ignored]).to eq '01010101010101010101' }

    context 'short length - 1' do
      let(:payload) { '000a'.htb }

      it { expect(subject.valid?).to eq false }
    end
  end

  describe '#to_payload' do
    subject { described_class.new(ignored: '01010101010101010101').to_payload }

    it { is_expected.to eq '0013000a01010101010101010101'.htb }
  end
end
