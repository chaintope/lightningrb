# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::WaitForInitInterval do
  subject(:action) { state.next(message, data) }

  let(:state) { described_class.new(channel, channel_context) }
  let(:data) { Algebrick::None }
  let(:spv) { create_test_spv }
  let(:channel_context) do
    build(:channel_context,
          context: build(:context, spv: spv, wallet: wallet),
          forwarder: forwarder)
  end
  let(:transport) { spawn_dummy_actor(name: :transport) }
  let(:forwarder) { spawn_dummy_actor(name: :forwarder) }
  let(:channel) { Lightning::Channel::Channel.spawn(:channel, channel_context) }
  let(:wallet) { double(:wallet) }

  describe 'with InputInitFunder' do
    let(:message) { build(:input_init_funder, remote: transport).get }

    it 'transition to WaitForAcceptChannel' do
      expect(action[0]).to be_a Lightning::Channel::ChannelState::WaitForAcceptChannel
      expect(action[1]).to be_a Lightning::Channel::Messages::DataWaitForAcceptChannel
    end

    it 'forward open_channel message' do
      expect(forwarder).to receive(:<<).with(transport)
      expect(forwarder).to receive(:<<).with(Lightning::Wire::LightningMessages::OpenChannel)
      action
      channel.ask(:await).wait
      forwarder.ask(:await).wait
    end
  end
end
