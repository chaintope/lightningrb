# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::ClosingSigned do
  let(:channel_id) { 'c5d2ab65b54f03586a7ae076287ab70292606a3325698ba8de061fe6bcd59cbf' }
  let(:fee_satoshis) { 2 }
  let(:signature) do
    '3045022100a7a81a45836b748556085d630dc2e11c2d836ff09b2ebd8cbde62c' \
    '8adafa9cc0022054bd636e8fabcf528fcc6b77e5870c5d6f775c2efa6819965d' \
    '88461f34eb247d'
  end
  let(:payload) do
    '0027c5d2ab65b54f03586a7ae076287ab70292606a3325698ba8de061fe6bcd5' \
    '9cbf0000000000000002a7a81a45836b748556085d630dc2e11c2d836ff09b2e' \
    'bd8cbde62c8adafa9cc054bd636e8fabcf528fcc6b77e5870c5d6f775c2efa68' \
    '19965d88461f34eb247d'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:fee_satoshis]).to eq fee_satoshis }
    it { expect(subject[:signature]).to eq signature }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        fee_satoshis,
        signature
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
