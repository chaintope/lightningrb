# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::FundingCreated do
  let(:temporary_channel_id) { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
  let(:funding_txid) { '0000000000000000000000000000000000000000000000000000000000000000' }
  let(:funding_output_index) { 3 }
  let(:signature) do
    Lightning::Wire::Signature.new(value:
      '3044022006738efd3950b5afde00bb3a751446b6f66a9f3aa922270f77e393d0' \
      'f94ef2ea022011e92f342b707aefd3defee91bdbb1a2fc2b824c9a542903d878' \
      '9b2a7e1a6088'
    )
  end
  let(:payload) do
    '002236155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb4' \
    '55af9b3357000000000000000000000000000000000000000000000000' \
    '0000000000000000000306738efd3950b5afde00bb3a751446b6f66a9f' \
    '3aa922270f77e393d0f94ef2ea11e92f342b707aefd3defee91bdbb1a2' \
    'fc2b824c9a542903d8789b2a7e1a6088'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.temporary_channel_id).to eq temporary_channel_id }
    it { expect(subject.funding_txid).to eq funding_txid }
    it { expect(subject.funding_output_index).to eq funding_output_index }
    it { expect(subject.signature).to eq signature }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        temporary_channel_id: temporary_channel_id,
        funding_txid: funding_txid,
        funding_output_index: funding_output_index,
        signature: signature,
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe '#validate!' do
    subject do
      described_class.new(
        temporary_channel_id: temporary_channel_id,
        funding_txid: funding_txid,
        funding_output_index: funding_output_index,
        signature: signature,
      ).validate!(open_temporary_channel_id)
    end

    let(:open_temporary_channel_id) { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }

    it { expect { subject }.not_to raise_error }

    describe 'The sender MUST set:' do
      describe 'temporary_channel_id the same as the temporary_channel_id in the open_channel message.' do
        let(:temporary_channel_id) { '0000000000000000000000000000000000000000000000000000000000000000' }
        it { expect { subject }.to raise_error(Lightning::Exceptions::TemporaryChannelIdNotMatch) }
      end
    end
  end
end
