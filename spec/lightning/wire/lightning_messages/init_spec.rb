# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Init do
  describe '#load' do
    subject { described_class.load(payload.htb) }

    let(:payload) { '001000010100020003' }

    it { expect(subject[:gflen]).to eq 1 }
    it { expect(subject[:globalfeatures]).to eq '01' }
    it { expect(subject[:lflen]).to eq 2 }
    it { expect(subject[:localfeatures]).to eq '0003' }

    context 'short length - 1' do
      let(:payload) { '0001'.htb }

      it { is_expected.to eq nil }
    end

    context 'short length - 2' do
      let(:payload) { '000101'.htb }

      it { is_expected.to eq nil }
    end

    context 'short length - 3' do
      let(:payload) { '0001010002'.htb }

      it { is_expected.to eq nil }
    end
  end

  describe '#to_payload' do
    subject { described_class[1, '01', 2, '0003'].to_payload }

    it { is_expected.to eq '001000010100020003'.htb }
  end
end
