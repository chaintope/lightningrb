# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState do
  describe '#on_transition' do
    subject { state.on_transition(channel, state, data, next_state, next_data) }

    let(:spv) { create_test_spv }
    let(:channel_context) do
      build(
        :channel_context,
        context: build(:context, spv: spv, wallet: wallet),
        transport: transport,
        forwarder: forwarder
      )
    end
    let(:transport) { spawn_dummy_actor(name: :transport) }
    let(:forwarder) { spawn_dummy_actor(name: :forwarder) }
    let(:channel) { Lightning::Channel::Channel.spawn(:channel, channel_context) }

    let(:wallet) { double(:wallet) }
    let(:state) { Lightning::Channel::ChannelState::WaitForOpenChannel.new(channel.reference, channel_context) }
    let(:data) { build(:data_wait_for_open_channel).get }
    let(:next_state) { Lightning::Channel::ChannelState::WaitForFundingCreated.new(channel.reference, channel_context) }
    let(:next_data) { build(:data_wait_for_funding_created).get }

    context 'channel state change' do
      it 'fire ChannelStateChanged event' do
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::ChannelStateChanged)
        subject
      end
    end

    context 'channel state does not change' do
      let(:next_state) { state }
      let(:next_data) { data }
      it 'does not fire ChannelStateChanged event' do
        expect(channel_context.broadcast).not_to receive(:<<).with(Lightning::Channel::Events::ChannelStateChanged)
        subject
      end
    end

    context 'new channel detected' do
      let(:state) { Lightning::Channel::ChannelState::WaitForFundingLocked.new(channel.reference, channel_context) }
      let(:data) { build(:data_wait_for_funding_locked).get }

      let(:next_state) { Lightning::Channel::ChannelState::Normal.new(channel.reference, channel_context) }
      let(:next_data) { build(:data_normal).get }

      it 'fire LocalChannelUpdate event' do
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::ChannelStateChanged).ordered
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::LocalChannelUpdate).ordered
        subject
      end
    end

    context 'channel_update and channel_announcement is not changed' do
      let(:state) { Lightning::Channel::ChannelState::Normal.new(channel.reference, channel_context) }
      let(:data) { build(:data_normal).get }

      let(:next_state) { Lightning::Channel::ChannelState::Normal.new(channel.reference, channel_context) }
      let(:next_data) { build(:data_normal).get }

      it 'does not fire LocalChannelUpdate event' do
        expect(channel_context.broadcast).not_to receive(:<<).with(Lightning::Channel::Events::LocalChannelUpdate)
        subject
      end
    end

    context 'channel goes to closing phase' do
      let(:state) { Lightning::Channel::ChannelState::Normal.new(channel.reference, channel_context) }
      let(:data) { build(:data_normal).get }

      let(:next_state) { Lightning::Channel::ChannelState::Shutdowning.new(channel.reference, channel_context) }
      let(:next_data) { build(:data_shutdown).get }

      it 'fire LocalChannelDown event' do
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::ChannelStateChanged).ordered
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::LocalChannelDown).ordered
        subject
      end
    end
  end
end