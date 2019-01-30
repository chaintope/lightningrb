# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::WaitForFundingInternal do
  subject(:action) { state.next(message, data) }

  let(:state) { described_class.new(channel, channel_context) }
  let(:data) { build(:data_wait_for_funding_internal).get }
  let(:spv) { create_test_spv }
  let(:channel_context) do
    build(:channel_context,
          context: build(:context, spv: spv, wallet: wallet),
          forwarder: forwarder)
  end
  let(:forwarder) { spawn_dummy_actor(name: :forwarder) }
  let(:channel) { Lightning::Channel::Channel.spawn(:channel, channel_context) }
  let(:wallet) { double(:wallet) }

  describe 'with MakeFundingTxResponse' do
    let(:message) { build(:make_funding_tx_response).get }

    it 'transition to WaitForFundingSigned' do
      expect(action[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingSigned
      expect(action[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingSigned
    end

    it 'forward funding_created message' do
      expect(forwarder).to receive(:<<).with(Lightning::Wire::LightningMessages::FundingCreated)
      action
      forwarder.ask(:await).wait
    end
  end
end
