# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::WaitForOpenChannel do
  subject(:action) { state.next(message, data) }

  let(:state) { described_class.new(channel, channel_context) }
  let(:data) { build(:data_wait_for_open_channel).get }
  let(:spv) { create_test_spv }
  let(:channel_context) do
    build(
      :channel_context,
      context: build(:context, spv: spv, wallet: wallet),
      forwarder: forwarder
    )
  end
  let(:forwarder) { spawn_dummy_actor(name: :forwarder) }
  let(:channel) { Lightning::Channel::Channel.spawn(:channel, channel_context) }
  let(:wallet) { double(:wallet) }

  describe 'with OpenChannel' do
    let(:message) { build(:open_channel).get }

    it 'transition to WaitForFundingCreated' do
      expect(action[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingCreated
      expect(action[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingCreated
    end

    it 'forward accept_channel message' do
      expect(forwarder).to receive(:<<).with(Lightning::Wire::LightningMessages::AcceptChannel)
      action
      forwarder.ask(:await).wait
    end
  end
end
