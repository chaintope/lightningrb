# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::WaitForAcceptChannel do
  subject(:action) { state.next(message, data) }

  let(:state) { described_class.new(channel, channel_context) }
  let(:data) { build(:data_wait_for_accept_channel).get }
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

  before do
    allow(spv).to receive(:wallet).and_return(wallet)
    allow(wallet).to receive(:complete).and_return(Bitcoin::Tx.new)
    allow(wallet).to receive(:commit).and_return(nil)
  end

  describe 'with AcceptChannel' do
    let(:message) { build(:accept_channel) }

    it 'transition to WaitForFundingCreated' do
      expect(action[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingInternal
      expect(action[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingInternal
    end

    it 'make funding tx' do
      expect(channel).to receive(:<<).with(Lightning::Transactions::Funding::MakeFundingTxResponse)
      action
      channel.ask(:await).wait
    end
  end
end
