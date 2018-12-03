# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::OpenChannel do
  let(:chain_hash) { '821c2ed9a347077ed90175802c9b06735222359091e7b5cc8edd3e1d62067842' }
  let(:temporary_channel_id) { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
  let(:funding_satoshis) { 3 }
  let(:push_msat) { 4 }
  let(:dust_limit_satoshis) { 5 }
  let(:max_htlc_value_in_flight_msat) { 6 }
  let(:channel_reserve_satoshis) { 7 }
  let(:htlc_minimum_msat) { 8 }
  let(:feerate_per_kw) { 9 }
  let(:to_self_delay) { 10 }
  let(:max_accepted_htlcs) { 11 }
  let(:funding_pubkey) { '031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f' }
  let(:revocation_basepoint) { '024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d0766' }
  let(:payment_basepoint) { '02531fe6068134503d2723133227c867ac8fa6c83c537e9a44c3c5bdbdcb1fe337' }
  let(:delayed_payment_basepoint) { '03462779ad4aad39514614751a71085f2f10e1c7a593e4e030efb5b8721ce55b0b' }
  let(:htlc_basepoint) { '0362c0a046dacce86ddd0343c6d3c7c79c2208ba0d9c9cf24a6d046d21d21f90f7' }
  let(:first_per_commitment_point) { '03f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a' }
  let(:channel_flags) { 0 }
  # let(:shutdown_len) { 0 }
  # let(:shutdown_scriptpubkey) { '' }
  let(:payload) do
    '0020821c2ed9a347077ed90175802c9b06735222359091e7b5cc8edd3e1d6206' \
    '784236155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b' \
    '3357000000000000000300000000000000040000000000000005000000000000' \
    '00060000000000000007000000000000000800000009000a000b031b84c5567b' \
    '126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f024d4b6cd1' \
    '361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d076602531fe6' \
    '068134503d2723133227c867ac8fa6c83c537e9a44c3c5bdbdcb1fe337034627' \
    '79ad4aad39514614751a71085f2f10e1c7a593e4e030efb5b8721ce55b0b0362' \
    'c0a046dacce86ddd0343c6d3c7c79c2208ba0d9c9cf24a6d046d21d21f90f703' \
    'f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a00'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject[:chain_hash]).to eq chain_hash }
    it { expect(subject[:temporary_channel_id]).to eq temporary_channel_id }
    it { expect(subject[:funding_satoshis]).to eq funding_satoshis }
    it { expect(subject[:push_msat]).to eq push_msat }
    it { expect(subject[:dust_limit_satoshis]).to eq dust_limit_satoshis }
    it { expect(subject[:max_htlc_value_in_flight_msat]).to eq max_htlc_value_in_flight_msat }
    it { expect(subject[:channel_reserve_satoshis]).to eq channel_reserve_satoshis }
    it { expect(subject[:htlc_minimum_msat]).to eq htlc_minimum_msat }
    it { expect(subject[:feerate_per_kw]).to eq feerate_per_kw }
    it { expect(subject[:to_self_delay]).to eq to_self_delay }
    it { expect(subject[:max_accepted_htlcs]).to eq max_accepted_htlcs }
    it { expect(subject[:funding_pubkey]).to eq funding_pubkey }
    it { expect(subject[:revocation_basepoint]).to eq revocation_basepoint }
    it { expect(subject[:payment_basepoint]).to eq payment_basepoint }
    it { expect(subject[:delayed_payment_basepoint]).to eq delayed_payment_basepoint }
    it { expect(subject[:htlc_basepoint]).to eq htlc_basepoint }
    it { expect(subject[:first_per_commitment_point]).to eq first_per_commitment_point }
    it { expect(subject[:channel_flags]).to eq channel_flags }
    # it { expect(subject[:shutdown_len]).to eq shutdown_len }
    # it { expect(subject[:shutdown_scriptpubkey]).to eq shutdown_scriptpubkey }
  end

  describe '#to_payload' do
    subject do
      described_class[
        chain_hash,
        temporary_channel_id,
        funding_satoshis,
        push_msat,
        dust_limit_satoshis,
        max_htlc_value_in_flight_msat,
        channel_reserve_satoshis,
        htlc_minimum_msat,
        feerate_per_kw,
        to_self_delay,
        max_accepted_htlcs,
        funding_pubkey,
        revocation_basepoint,
        payment_basepoint,
        delayed_payment_basepoint,
        htlc_basepoint,
        first_per_commitment_point,
        channel_flags,
        # shutdown_len,
        # shutdown_scriptpubkey
      ].to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe '#validate!' do
    subject { build(:open_channel).get }
    it { expect{ subject.validate! }.not_to raise_error }

    describe 'MUST set funding_satoshis to less than 2^24 satoshi.' do
      subject { build(:open_channel, funding_satoshis: 2**24).get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::AmountTooLarge) }
    end

    describe 'MUST set push_msat to equal or less than 1000 * funding_satoshis.' do
      subject { build(:open_channel, push_msat: 1_000_000_001).get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::PushMsatTooLarge) }
    end

    describe 'MUST set funding_pubkey to valid DER-encoded, compressed, secp256k1 pubkeys.' do
      subject { build(:open_channel, funding_pubkey: '0203040506070809000102030405060708090001020304050607080900010203').get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InvalidKeyFormat) }
    end

    describe 'MUST set revocation_basepoint to valid DER-encoded, compressed, secp256k1 pubkeys.' do
      subject { build(:open_channel, revocation_basepoint: '0203040506070809000102030405060708090001020304050607080900010203').get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InvalidKeyFormat) }
    end

    describe 'MUST set htlc_basepoint to valid DER-encoded, compressed, secp256k1 pubkeys.' do
      subject { build(:open_channel, htlc_basepoint: '0203040506070809000102030405060708090001020304050607080900010203').get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InvalidKeyFormat) }
    end

    describe 'MUST set payment_basepoint to valid DER-encoded, compressed, secp256k1 pubkeys.' do
      subject { build(:open_channel, payment_basepoint: '0203040506070809000102030405060708090001020304050607080900010203').get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InvalidKeyFormat) }
    end

    describe 'MUST set delayed_payment_basepoint to valid DER-encoded, compressed, secp256k1 pubkeys.' do
      subject { build(:open_channel, delayed_payment_basepoint: '0203040506070809000102030405060708090001020304050607080900010203').get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InvalidKeyFormat) }
    end

    xdescribe 'MUST set first_per_commitment_point to the per-commitment point to be used for the initial commitment transaction' do

    end

    describe 'MUST set channel_reserve_satoshis greater than or equal to dust_limit_satoshis.' do
      subject { build(:open_channel, channel_reserve_satoshis: 545).get }
      it { expect{ subject.validate! }.to raise_error(Lightning::Exceptions::InsufficientChannelReserve) }
    end

    xdescribe 'MUST set undefined bits in channel_flags to 0.' do

    end

    context 'if both nodes advertised the option_upfront_shutdown_script feature:' do
      xdescribe 'MUST include either a valid shutdown_scriptpubkey as required by shutdown scriptpubkey, or a zero-length shutdown_scriptpubkey' do
      end
    end
  end
end
