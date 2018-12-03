# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Pong do
  describe '#load' do
    subject { described_class.load(payload) }

    let(:payload) { '0013000a01010101010101010101'.htb }

    it { expect(subject[:byteslen]).to eq 10 }
    it { expect(subject[:ignored].bth).to eq '01010101010101010101' }

    context 'short length - 1' do
      let(:payload) { '000a'.htb }

      it { is_expected.to eq nil }
    end
  end

  describe '#to_payload' do
    subject { described_class[10, '01010101010101010101'.htb].to_payload }

    it { is_expected.to eq '0013000a01010101010101010101'.htb }
  end
end
