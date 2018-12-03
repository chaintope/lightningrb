# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::CommitmentSigned do
  let(:channel_id) { '7846ffda34597edec8e26682fb9d10ac81b6405a6a2b4e6e86ed0718c9ece503' }
  let(:signature) do
    '304402200191792790e7f616bf1a4251a54f1345fe0a0880eec2242f04d5c280' \
    '41f9047502206eb5b8d04a9fbdf2e99b3b883b62dc88f4a528e7ceae8e41fe0f' \
    'bf447e157f3c'
  end
  let(:num_htlcs) { 3 }
  let(:htlc_signature) do
    [
      '3044022020ae69da79561017dec0a5440ec4678b4032b19bdd89dc8353daa389' \
      'b1dfab590220458536d6144c40c319c443a5b2e4c00de3667a7bcec26ff832ab' \
      'f83d4a828032',
      '3045022100c20e1eb01bd1d314c2fa734a2053c59ef28a442db2f35d17c2fa46' \
      '139d56a4e20220398b238b44cd80c299e082a295d23af6b7ce0042382318c5a5' \
      '96a344d12621cf',
      '304402206f0297c2796aa82272f998f93315e86317a2b22bd6a18a869a32f1ff' \
      '2f53802e022026ae1e764477d724f2c5e93243052000904c4442736ec41236d8' \
      '0739fc3ddfcd',
    ]
  end
  let(:payload) do
    '00847846ffda34597edec8e26682fb9d10ac81b6405a6a2b4e6e86ed0718c9ec' \
    'e5030191792790e7f616bf1a4251a54f1345fe0a0880eec2242f04d5c28041f9' \
    '04756eb5b8d04a9fbdf2e99b3b883b62dc88f4a528e7ceae8e41fe0fbf447e15' \
    '7f3c000320ae69da79561017dec0a5440ec4678b4032b19bdd89dc8353daa389' \
    'b1dfab59458536d6144c40c319c443a5b2e4c00de3667a7bcec26ff832abf83d' \
    '4a828032c20e1eb01bd1d314c2fa734a2053c59ef28a442db2f35d17c2fa4613' \
    '9d56a4e2398b238b44cd80c299e082a295d23af6b7ce0042382318c5a596a344' \
    'd12621cf6f0297c2796aa82272f998f93315e86317a2b22bd6a18a869a32f1ff' \
    '2f53802e26ae1e764477d724f2c5e93243052000904c4442736ec41236d80739' \
    'fc3ddfcd'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:channel_id]).to eq channel_id }
    it { expect(subject[:signature]).to eq signature }
    it { expect(subject[:num_htlcs]).to eq num_htlcs }
    it { expect(subject[:htlc_signature]).to eq htlc_signature }
  end

  describe '#to_payload' do
    subject do
      described_class[
        channel_id,
        signature,
        num_htlcs,
        htlc_signature
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end
end
