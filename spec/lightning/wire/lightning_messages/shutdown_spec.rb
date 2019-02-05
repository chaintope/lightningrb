# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::Shutdown do
  let(:channel_id) { '268a04bfb4918c9a035021766145eb2cd0c55dcfff2c56cb04c5f956740a7001' }
  let(:len) { 47 }
  let(:scriptpubkey) do
    '0000000000000000000000000000000000000000000000000000000000000000' \
    '000000000000000000000000000000'
  end

  let(:payload) do
    '0026268a04bfb4918c9a035021766145eb2cd0c55dcfff2c56cb04c5f956740a' \
    '7001002f00000000000000000000000000000000000000000000000000000000' \
    '00000000000000000000000000000000000000'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.channel_id).to eq channel_id }
    it { expect(subject.scriptpubkey).to eq scriptpubkey }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        channel_id: channel_id,
        scriptpubkey: scriptpubkey
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
