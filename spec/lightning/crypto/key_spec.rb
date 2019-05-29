# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Crypto::Key do
  describe 'derive_public_key' do
    subject { described_class.derive_public_key(base_point, per_commitment_point) }

    let(:base_point) { '036d6caac248af96f6afa7f904f550253a0f3ef3f5aa2fe6838a95b216691468e2' }
    let(:per_commitment_point) { '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486' }

    it { is_expected.to eq '0235f2dbfaa89b57ec7b055afe29849ef7ddfeb1cefdb9ebdc43f5494984db29e5' }
  end

  describe 'derive_private_key' do
    subject { described_class.derive_private_key(base_point_secret, per_commitment_point) }

    let(:base_point_secret) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    let(:per_commitment_point) { '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486' }

    it { is_expected.to eq 'cbced912d3b21bf196a766651e436aff192362621ce317704ea2f75d87e7be0f' }

    context 'when overflow group order' do
      let(:base_point_secret) { 'e787680a1f1f301d59daad282218720dff4cbf7c45f5efd609e6b0d86cab88e9' }
      let(:per_commitment_point) { '03078f2a3c8e65dcc7af1cba390a0d412c90145b017702ba94a1327a32a5437ebe' }

      it { is_expected.to eq '3ba635eaffe022548f4ee9141c90d0ca3c233b570351f9086e40d085a2c6fc88' }
    end
  end

  describe 'revocation_public_key_open_ssl' do
    subject { described_class.revocation_public_key_open_ssl(base_point, per_commitment_point) }

    let(:base_point) { '036d6caac248af96f6afa7f904f550253a0f3ef3f5aa2fe6838a95b216691468e2' }
    let(:per_commitment_point) { '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486' }

    it { is_expected.to eq '02916e326636d19c33f13e8c0c3a03dd157f332f3e99c317c141dd865eb01f8ff0' }
  end

  describe 'revocation_public_key_pure' do
    subject { described_class.revocation_public_key_pure(base_point, per_commitment_point) }

    let(:base_point) { '036d6caac248af96f6afa7f904f550253a0f3ef3f5aa2fe6838a95b216691468e2' }
    let(:per_commitment_point) { '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486' }

    it { is_expected.to eq '02916e326636d19c33f13e8c0c3a03dd157f332f3e99c317c141dd865eb01f8ff0' }
  end

  describe 'revocation_private_key' do
    subject { described_class.revocation_private_key(secret, per_commitment_secret) }

    let(:secret) { '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f' }
    let(:per_commitment_secret) { '1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100' }

    it { is_expected.to eq 'd09ffff62ddb2297ab000cc85bcb4283fdeb6aa052affbc9dddcf33b61078110' }
  end

  describe 'per_commitment_secret' do
    test_vector =
      [
        {
          seed: '0000000000000000000000000000000000000000000000000000000000000000',
          i: 0,
          output: '02a40c85b6f28da08dfdbe0926c53fab2de6d28c10301f8f7c4073d5e42e3148',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 0,
          output: '7cc854b54e3e0dcdb010d7a3fee464a9687be6e8db3be6854c475621e007a5dc',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 269_746_852_681_045,
          output: '56f4008fb007ca9acf0e15b054d5c9fd12ee06cea347914ddbaed70d1c13a528',
        }, {
          seed: 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF',
          i: 187_649_984_473_770,
          output: '9015daaeb06dba4ccc05b91b2f73bd54405f2be9f217fbacd3c5ac2e62327d31',
        }, {
          seed: '0101010101010101010101010101010101010101010101010101010101010101',
          i: 281_474_976_710_654,
          output: '915c75942a26bb3a433a8ce2cb0427c29ec6c1775cfc78328b57f6ba7bfeaa9c',
        },
      ]
    test_vector.each_with_index do |v, i|
      context "vector - #{i}" do
        subject { described_class.per_commitment_secret(v[:seed], v[:i]) }

        it { is_expected.to eq v[:output] }
      end
    end
  end
end
