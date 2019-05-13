# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Payment::Relayer do
  describe '#on_message' do
    subject do
      relayer << message
      relayer.ask(:await).wait
    end

    let(:private_key) { '41' * 32 }
    let(:node_param) { build(:node_param, private_key: private_key) }
    let(:context) { build(:context, node_params: node_param, spv: spv) }
    let(:spv) { create_test_spv }
    let(:relayer) { described_class.spawn(:relayer, context) }
    let(:channel) { spawn_dummy_actor }
    let(:channel_announcement) { build(:channel_announcement) }
    let(:channel_update) { build(:channel_update) }

    before { spv.stub(:block_height).and_return(999) }

    describe 'ChannelStateChanged' do
    end

    describe 'LocalChannelUpdate' do
      let(:message) do
        Lightning::Channel::Events::LocalChannelUpdate.build(
          channel, channel_announcement, channel_update,
          short_channel_id: 42,
          remote_node_id: '11' * 33,
          channel_id: '00' * 32
        )
      end

      it do
        subject
        expect(relayer.ask!(:channel_updates)[42]).to eq message.channel_update
      end
    end

    describe 'LocalChannelDown' do
      let(:message) do
        Lightning::Channel::Events::LocalChannelDown.build(channel,
          short_channel_id: 42,
          remote_node_id: '11' * 33,
          channel_id: '00' * 32
        )
      end
      let(:local_channel_update) do
        Lightning::Channel::Events::LocalChannelUpdate.build(
          channel, channel_announcement, channel_update,
          short_channel_id: 42,
          remote_node_id: '11' * 33,
          channel_id: '00' * 32
        )
      end

      before { relayer << local_channel_update }

      it do
        expect(relayer.ask!(:channel_updates).size).to eq 1
        subject
        expect(relayer.ask!(:channel_updates).size).to eq 0
      end
    end

    describe 'ForwardAdd' do
      include Lightning::Payment::RouteBuilder

      let(:message) { Lightning::Payment::Relayer::ForwardAdd[add] }

      let(:keys) do
        [
          Bitcoin::Key.new(priv_key: '41' * 32),
          Bitcoin::Key.new(priv_key: '42' * 32),
          Bitcoin::Key.new(priv_key: '43' * 32),
          Bitcoin::Key.new(priv_key: '44' * 32),
          Bitcoin::Key.new(priv_key: '45' * 32),
        ]
      end
      let(:public_keys) { keys.map(&:pubkey) }
      let(:sig) { keys[0].sign(Bitcoin.sha256('')).bth }
      let(:channel_update) do
        Lightning::Wire::LightningMessages::ChannelUpdate.new(
          signature: Lightning::Wire::Signature.new(value: sig),
          chain_hash1: '00' * 32,
          short_channel_id: 0,
          timestamp: 0,
          message_flags: "00",
          channel_flags: "00",
          cltv_expiry_delta: 42000,
          htlc_minimum_msat: 0,
          fee_base_msat: 0,
          fee_proportional_millionths: 0,
          htlc_maximum_msat: 0
        )
    end
      let(:channel_update_ab) do
        channel_update.copy(short_channel_id: 1, cltv_expiry_delta: 4, fee_base_msat: 642000, fee_proportional_millionths: 7)
      end
      let(:channel_update_bc) do
        channel_update.copy(short_channel_id: 2, cltv_expiry_delta: 5, fee_base_msat: 153000, fee_proportional_millionths: 4)
      end
      let(:channel_update_cd) do
        channel_update.copy(short_channel_id: 3, cltv_expiry_delta: 10, fee_base_msat: 60000, fee_proportional_millionths: 1)
      end
      let(:channel_update_de) do
        channel_update.copy(short_channel_id: 4, cltv_expiry_delta: 7, fee_base_msat: 766000, fee_proportional_millionths: 10)
      end
      let(:hops) do
        [
          Lightning::Router::Messages::Hop[public_keys[0], public_keys[1], channel_update_ab],
          Lightning::Router::Messages::Hop[public_keys[1], public_keys[2], channel_update_bc],
          Lightning::Router::Messages::Hop[public_keys[2], public_keys[3], channel_update_cd],
          Lightning::Router::Messages::Hop[public_keys[3], public_keys[4], channel_update_de],
        ]
      end
      let(:final_amount_msat) { 42_000_000 }
      let(:current_block_count) { 420_000 }
      let(:final_expiry) { 420_009 }
      let(:payment_hash) { "\x42" * 32 }
      let(:expiry_de) { final_expiry }
      let(:amount_de) { final_amount_msat }
      let(:fee_d) { node_fee(channel_update_de.fee_base_msat, channel_update_de.fee_proportional_millionths, amount_de) }
      let(:expiry_cd) { expiry_de + channel_update_de.cltv_expiry_delta }
      let(:amount_cd) { amount_de + fee_d }
      let(:fee_c) { node_fee(channel_update_cd.fee_base_msat, channel_update_cd.fee_proportional_millionths, amount_cd) }
      let(:expiry_bc) { expiry_cd + channel_update_cd.cltv_expiry_delta }
      let(:amount_bc) { amount_cd + fee_c }
      let(:fee_b) { node_fee(channel_update_bc.fee_base_msat, channel_update_bc.fee_proportional_millionths, amount_bc) }
      let(:expiry_ab) { expiry_bc + channel_update_bc.cltv_expiry_delta }
      let(:amount_ab) { amount_bc + fee_b }

      let(:command_add_htlc) { build_command(final_amount_msat, final_expiry, payment_hash, hops)[0] }
      let(:amount_msat) { 42_000_000 }
      let(:add) do
        build(
          :update_add_htlc,
          channel_id: '11' * 32,
          id: 123_456,
          amount_msat: command_add_htlc[:amount_msat],
          cltv_expiry: command_add_htlc[:cltv_expiry],
          onion_routing_packet: command_add_htlc[:onion]
        )
      end
      let(:local_channel_update) do
        Lightning::Channel::Events::LocalChannelUpdate.build(
          channel, channel_announcement, channel_update_bc,
          short_channel_id: 2,
          remote_node_id: public_keys[2]
        )
      end

      before { relayer << local_channel_update }

      context 'with no error' do
        let(:private_key) { '42' * 32 }

        it do
          expect(context.register).to receive(:<<).with(Lightning::Channel::Register::ForwardShortId)
          subject
          context.register.ask(:await).wait
        end
      end

      context 'when last packet' do
        let(:private_key) { '42' * 32 }
        let(:hops) do
          [
            Lightning::Router::Messages::Hop[public_keys[0], public_keys[1], channel_update_ab],
          ]
        end

        it do
          expect(context.payment_handler).to receive(:<<).with(Lightning::Wire::LightningMessages::UpdateAddHtlc)
          subject
        end
      end
    end

    describe 'ForwardFulfill' do
      let(:message) { Lightning::Payment::Relayer::ForwardFulfill[fulfill, to, htlc] }
      let(:fulfill) { build(:update_fulfill_htlc) }
      let(:htlc) { build(:update_add_htlc) }

      context 'to local' do
        let(:to) { Lightning::Payment::Relayer::Local }

        it do
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Lightning::Payment::Events::PaymentSucceeded).ordered
          subject
        end
      end

      context 'to remote' do
        let(:to) { Lightning::Payment::Relayer::Relayed['00' * 32, 1, 1000, 2000] }

        it do
          expect(context.register).to receive(:<<).with(Lightning::Channel::Register::Forward)
          subject
        end
      end
    end

    describe 'ForwardFail' do
      let(:message) { Lightning::Payment::Relayer::ForwardFail[fail, to, htlc] }
      let(:fail) { build(:update_fail_htlc) }
      let(:htlc) { build(:update_add_htlc) }

      context 'to local' do
        let(:to) { Lightning::Payment::Relayer::Local }

        it do
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Lightning::Payment::Events::PaymentFailed).ordered
          subject
        end
      end

      context 'to remote' do
        let(:to) { Lightning::Payment::Relayer::Relayed['00' * 32, 1, 1000, 2000] }

        it do
          expect(context.register).to receive(:<<).with(Lightning::Channel::Register::Forward).ordered
          subject
        end
      end
    end

    describe 'ForwardFailMalformed' do
      let(:message) { Lightning::Payment::Relayer::ForwardFailMalformed[fail, to, htlc] }
      let(:fail) { build(:update_fail_malformed_htlc) }
      let(:htlc) { build(:update_add_htlc) }

      context 'to local' do
        let(:to) { Lightning::Payment::Relayer::Local }

        it do
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Array).ordered
          expect(context.broadcast).to receive(:<<).with(Lightning::Payment::Events::PaymentFailed)
          subject
        end
      end

      context 'to remote' do
        let(:to) { Lightning::Payment::Relayer::Relayed['00' * 32, 1, 1000, 2000] }

        it do
          expect(context.register).to receive(:<<).with(Lightning::Channel::Register::Forward)
          subject
        end
      end
    end
  end
end
