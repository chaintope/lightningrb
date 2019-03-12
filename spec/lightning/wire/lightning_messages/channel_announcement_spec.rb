# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::ChannelAnnouncement do
  let(:node_signature_1) do
    Lightning::Wire::Signature.new(value:
      '30440220401116d5aab3a83ae795d7f15094934f69e7841595efd2e3ef6b1632' \
      '52f3c656022059a91ebd36f8a4ecd44365fcde54bfa3ad0ac76b252baef6e1d9' \
      '098fa9629d20'
    )
  end
  let(:node_signature_2) do
    Lightning::Wire::Signature.new(value:
      '30440220688224c115241fe5f10261127f926ea84196148631ca35af01cbdb14' \
      '1ab175a1022046e47ba3e6eb8216690403f49a9e874eb2dd71d88339587a617d' \
      'bc8dcab7b5c8'
    )
  end
  let(:bitcoin_signature_1) do
    Lightning::Wire::Signature.new(value:
      '3045022100f8c1ee009aebdcb9cc745b5041f347d6042978f3526d10d629a054' \
      'b4d71a3ae9022058a642cf5bdced1716886ef1ab52f88f4e9d49a70a83a694a0' \
      '8354e3653821d5'
    )
  end
  let(:bitcoin_signature_2) do
    Lightning::Wire::Signature.new(value:
      '304402204b49ba49a24db1aa6877cda8b701f5c08a849950dc775be91c4fb1a9' \
      'b8ec72c30220311d6c98e349b1f18b8d1e84d81fa80cee64e89948d88cea075e' \
      '08feed46abdd'
    )
  end
  let(:features) { '09090909090909' }
  let(:chain_hash) { '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f' }
  let(:short_channel_id) { 1 }
  let(:node_id_1) { '02adb02766bbc6c1fc9d2998e00f5832a2056cc9abd7b26dde33191f1c15b62982' }
  let(:node_id_2) { '02f2f511b8eeed6bdb12be955e173f09f506fd9e447a1b9a66ee670b54451f93b0' }
  let(:bitcoin_key_1) { '024e3d9ba051271e4165616e6319f873ea6f83079fc810d78b0249bf8b860d89fb' }
  let(:bitcoin_key_2) { '02ba3025e9a83d7434b8c1a633dabc3189fee0cf91fe4a76bd381c661bfef26038' }
  let(:payload) do
    '0100401116d5aab3a83ae795d7f15094934f69e7841595efd2e3ef6b163252f3' \
    'c65659a91ebd36f8a4ecd44365fcde54bfa3ad0ac76b252baef6e1d9098fa962' \
    '9d20688224c115241fe5f10261127f926ea84196148631ca35af01cbdb141ab1' \
    '75a146e47ba3e6eb8216690403f49a9e874eb2dd71d88339587a617dbc8dcab7' \
    'b5c8f8c1ee009aebdcb9cc745b5041f347d6042978f3526d10d629a054b4d71a' \
    '3ae958a642cf5bdced1716886ef1ab52f88f4e9d49a70a83a694a08354e36538' \
    '21d54b49ba49a24db1aa6877cda8b701f5c08a849950dc775be91c4fb1a9b8ec' \
    '72c3311d6c98e349b1f18b8d1e84d81fa80cee64e89948d88cea075e08feed46' \
    'abdd00070909090909090906226e46111a0b59caaf126043eb5bbf28c34f3a5e' \
    '332a1fc7b2b73cf188910f000000000000000102adb02766bbc6c1fc9d2998e0' \
    '0f5832a2056cc9abd7b26dde33191f1c15b6298202f2f511b8eeed6bdb12be95' \
    '5e173f09f506fd9e447a1b9a66ee670b54451f93b0024e3d9ba051271e416561' \
    '6e6319f873ea6f83079fc810d78b0249bf8b860d89fb02ba3025e9a83d7434b8' \
    'c1a633dabc3189fee0cf91fe4a76bd381c661bfef26038'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.node_signature_1).to eq node_signature_1 }
    it { expect(subject.node_signature_2).to eq node_signature_2 }
    it { expect(subject.bitcoin_signature_1).to eq bitcoin_signature_1 }
    it { expect(subject.bitcoin_signature_2).to eq bitcoin_signature_2 }
    it { expect(subject.features).to eq features }
    it { expect(subject.chain_hash).to eq chain_hash }
    it { expect(subject.short_channel_id).to eq short_channel_id }
    it { expect(subject.node_id_1).to eq node_id_1 }
    it { expect(subject.node_id_2).to eq node_id_2 }
    it { expect(subject.bitcoin_key_1).to eq bitcoin_key_1 }
    it { expect(subject.bitcoin_key_2).to eq bitcoin_key_2 }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        node_signature_1: node_signature_1,
        node_signature_2: node_signature_2,
        bitcoin_signature_1: bitcoin_signature_1,
        bitcoin_signature_2: bitcoin_signature_2,
        features: features,
        chain_hash: chain_hash,
        short_channel_id: short_channel_id,
        node_id_1: node_id_1,
        node_id_2: node_id_2,
        bitcoin_key_1: bitcoin_key_1,
        bitcoin_key_2: bitcoin_key_2
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
