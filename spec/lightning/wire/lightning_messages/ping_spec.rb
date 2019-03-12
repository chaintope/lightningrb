# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Ping do
  describe '#load' do
    subject { described_class.load(payload) }

    let(:payload) { '00120064000a01010101010101010101'.htb }

    it { expect(subject.num_pong_bytes).to eq 100 }
    it { expect(subject.ignored).to eq '01010101010101010101' }

    context 'short length - 1' do
      let(:payload) { '0001'.htb }

      it { expect(subject.valid?).to eq false }
    end
  end

  describe '#to_payload' do
    subject { described_class.new(num_pong_bytes: 100, ignored: '01010101010101010101').to_payload }

    it { is_expected.to eq '00120064000a01010101010101010101'.htb }
  end
end
