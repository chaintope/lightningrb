# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Wire::LightningMessages::AcceptChannel do
  let(:temporary_channel_id) { 'e574c5fe67a7573b033a861e8202dbc68728183d216ab42ab3bc697c5a82f7d3' }
  let(:dust_limit_satoshis) { 3 }
  let(:max_htlc_value_in_flight_msat) { 4 }
  let(:channel_reserve_satoshis) { 5 }
  let(:htlc_minimum_msat) { 6 }
  let(:minimum_depth) { 7 }
  let(:to_self_delay) { 8 }
  let(:max_accepted_htlcs) { 9 }
  let(:funding_pubkey) { '031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f' }
  let(:revocation_basepoint) { '024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead80ac9423374c451a7254d0766' }
  let(:payment_basepoint) { '02531fe6068134503d2723133227c867ac8fa6c83c537e9a44c3c5bdbdcb1fe337' }
  let(:delayed_payment_basepoint) { '03462779ad4aad39514614751a71085f2f10e1c7a593e4e030efb5b8721ce55b0b' }
  let(:htlc_basepoint) { '0362c0a046dacce86ddd0343c6d3c7c79c2208ba0d9c9cf24a6d046d21d21f90f7' }
  let(:first_per_commitment_point) { '03f006a18d5653c4edf5391ff23a61f03ff83d237e880ee61187fa9f379a028e0a' }
  let(:shutdown_scriptpubkey) { '0014ccf1af2f2aabee14bb40fa3851ab2301de843110' }
  let(:payload) do
    '0021e574c5fe67a7573b033a861e8202dbc68728183d216ab42ab3bc697c5a82' \
    'f7d3000000000000000300000000000000040000000000000005000000000000' \
    '00060000000700080009031b84c5567b126440995d3ed5aaba0565d71e183460' \
    '4819ff9c17f5e9d5dd078f024d4b6cd1361032ca9bd2aeb9d900aa4d45d9ead8' \
    '0ac9423374c451a7254d076602531fe6068134503d2723133227c867ac8fa6c8' \
    '3c537e9a44c3c5bdbdcb1fe33703462779ad4aad39514614751a71085f2f10e1' \
    'c7a593e4e030efb5b8721ce55b0b0362c0a046dacce86ddd0343c6d3c7c79c22' \
    '08ba0d9c9cf24a6d046d21d21f90f703f006a18d5653c4edf5391ff23a61f03f' \
    'f83d237e880ee61187fa9f379a028e0a00160014ccf1af2f2aabee14bb40fa3851ab2301de843110'
  end

  describe '#load' do
    subject { described_class.load(payload.htb) }

    it { expect(subject.temporary_channel_id).to eq temporary_channel_id }
    it { expect(subject.dust_limit_satoshis).to eq dust_limit_satoshis }
    it { expect(subject.max_htlc_value_in_flight_msat).to eq max_htlc_value_in_flight_msat }
    it { expect(subject.channel_reserve_satoshis).to eq channel_reserve_satoshis }
    it { expect(subject.htlc_minimum_msat).to eq htlc_minimum_msat }
    it { expect(subject.minimum_depth).to eq minimum_depth }
    it { expect(subject.to_self_delay).to eq to_self_delay }
    it { expect(subject.max_accepted_htlcs).to eq max_accepted_htlcs }
    it { expect(subject.funding_pubkey).to eq funding_pubkey }
    it { expect(subject.revocation_basepoint).to eq revocation_basepoint }
    it { expect(subject.payment_basepoint).to eq payment_basepoint }
    it { expect(subject.delayed_payment_basepoint).to eq delayed_payment_basepoint }
    it { expect(subject.htlc_basepoint).to eq htlc_basepoint }
    it { expect(subject.first_per_commitment_point).to eq first_per_commitment_point }
    it { expect(subject.shutdown_scriptpubkey).to eq shutdown_scriptpubkey }
  end

  describe '#to_payload' do
    subject do
      described_class.new(
        temporary_channel_id: temporary_channel_id,
        dust_limit_satoshis: dust_limit_satoshis,
        max_htlc_value_in_flight_msat: max_htlc_value_in_flight_msat,
        channel_reserve_satoshis: channel_reserve_satoshis,
        htlc_minimum_msat: htlc_minimum_msat,
        minimum_depth: minimum_depth,
        to_self_delay: to_self_delay,
        max_accepted_htlcs: max_accepted_htlcs,
        funding_pubkey: funding_pubkey,
        revocation_basepoint: revocation_basepoint,
        payment_basepoint: payment_basepoint,
        delayed_payment_basepoint: delayed_payment_basepoint,
        htlc_basepoint: htlc_basepoint,
        first_per_commitment_point: first_per_commitment_point,
        shutdown_scriptpubkey: shutdown_scriptpubkey
      ).to_payload.bth
    end

    it { is_expected.to eq payload }
  end

  describe '#valid?' do
    subject { accept }

    let(:accept) { build(:accept_channel) }
    let(:open) { build(:open_channel) }

    it { expect { subject.validate!(open) }.not_to raise_error }

    describe 'The temporary_channel_id MUST be the same as the temporary_channel_id in the open_channel message.' do
      let(:open) { build(:open_channel, temporary_channel_id: '00' * 32) }

      it { expect { subject.validate!(open) }.to raise_error(Lightning::Exceptions::TemporaryChannelIdNotMatch) }
    end

    xdescribe 'The sender:' do
      xdescribe 'SHOULD set minimum_depth to a number of blocks it considers reasonable to avoid double-spending.' do
        pending("Not implement #{__LINE__}")
      end

      xdescribe 'MUST set channel_reserve_satoshis greater than or equal to dust_limit_satoshis from the open_channel message.' do
        pending("Not implement #{__LINE__}")
      end

      xdescribe 'MUST set dust_limit_satoshis less than or equal to channel_reserve_satoshis from the open_channel message.' do
        pending("Not implement #{__LINE__}")
      end
    end

    describe 'The receiver:' do
      xdescribe 'if minimum_depth is unreasonably large:' do
        pending("Not implement #{__LINE__}")
      end

      describe 'if channel_reserve_satoshis is less than dust_limit_satoshis within the open_channel message:' do
        let(:accept) { build(:accept_channel, channel_reserve_satoshis: 545) }

        it 'MUST reject the channel.' do
          expect { subject.validate!(open) }.to raise_error(Lightning::Exceptions::InsufficientChannelReserve)
        end
      end

      describe 'if channel_reserve_satoshis from the open_channel message is less than dust_limit_satoshis:' do
        let(:accept) { build(:accept_channel, dust_limit_satoshis: 10_001) }

        it 'MUST reject the channel.' do
          expect { subject.validate!(open) }.to raise_error(Lightning::Exceptions::InsufficientChannelReserve)
        end
      end
    end
  end
end
