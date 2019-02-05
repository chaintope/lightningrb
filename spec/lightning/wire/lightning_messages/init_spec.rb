# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Init do
  describe '#load' do
    subject { described_class.load(payload.htb) }

    let(:payload) { '001000010100020003' }

    it { expect(subject.type).to eq 16 }
    it { expect(subject.globalfeatures).to eq '01' }
    it { expect(subject.localfeatures).to eq '0003' }
  end

  describe '#to_payload' do
    subject { described_class.new(globalfeatures: '01', localfeatures: '0003').to_payload }

    it { is_expected.to eq '001000010100020003'.htb }
  end
end
