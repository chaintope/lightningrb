# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::WaitForFundingCreated do
  subject(:action) { state.next(message, data) }

  let(:state) { described_class.new(channel, channel_context) }
  let(:data) { build(:data_wait_for_funding_created).get }
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

  before { allow(Lightning::Transactions).to receive(:add_sigs).and_return(Bitcoin::Tx.new) }

  describe 'with FundingCreated' do
    let(:message) { build(:funding_created).get }

    it 'transition to WaitForFundingCreated' do
      expect(action[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingConfirmed
      expect(action[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingConfirmed
    end

    it 'forward funding_signed message' do
      expect(forwarder).to receive(:<<).with(Lightning::Wire::LightningMessages::FundingSigned)
      action
      channel.ask(:await).wait
      forwarder.ask(:await).wait
    end

    it 'add txid to the watch list' do
      expect(channel_context.blockchain).to receive(:<<).with(Lightning::Blockchain::Messages::WatchConfirmed)
      action
      channel.ask(:await).wait
      channel_context.blockchain.ask(:await).wait
    end
  end
end
