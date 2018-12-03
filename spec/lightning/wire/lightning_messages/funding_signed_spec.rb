# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::FundingSigned do
  let(:channel_id) { 'dba7c7b18968918a94fa127f7a5f47521c0dcb0be083da1ff4b15b4950aa9cdc' }
  let(:signature) do
    '30440220774a03d7dfda37030654b8f9bc93c00c68a5902560582b2bd7daa9a3' \
    '6aaaccb302204ca905e987633c6ecdc499f16224d660d039b1ca58796febf903' \
    '0b1b61fb95c1'
  end
  let(:payload) do
    '0023dba7c7b18968918a94fa127f7a5f47521c0dcb0be083da1ff4b15b' \
    '4950aa9cdc774a03d7dfda37030654b8f9bc93c00c68a5902560582b2b' \
    'd7daa9a36aaaccb34ca905e987633c6ecdc499f16224d660d039b1ca58' \
    '796febf9030b1b61fb95c1'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:signature]).to eq signature }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        signature,
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
