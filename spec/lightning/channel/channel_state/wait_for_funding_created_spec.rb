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
      forwarder: forwarder
    )
  end
  let(:forwarder) { spawn_dummy_actor(name: :forwarder) }
  let(:channel) { Lightning::Channel::Channel.spawn(:channel, channel_context) }
  let(:wallet) { double(:wallet) }
  # Transactions.sign(local_commit_tx.tx, local_commit_tx.utxo, Bitcoin::Key.new(priv_key: "1552dfba4f6cf29a62a0af13c8d6981d36d0ef8d61ba10fb0fe90da7634d7e13"))
  let(:signature) { Lightning::Wire::Signature.new(value: "3044022023bcc5b045c0b7d17b82a70b8e13c9fef70f53aebaf6cf5f60542e1380cd9cc00220454e089f6040db7afcc0a7d8604981ca3263f984cfae97389a6b49279ce5b09b") }

  describe 'with FundingCreated' do
    let(:message) { build(:funding_created, signature: signature) }

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

    it 'add penalty transaction to the watch tower' do
      expect(channel_context.watch_tower).to receive(:<<).with(Lightning::Blockchain::WatchTower::Register)
      action
      channel.ask(:await).wait
      channel_context.watch_tower.ask(:await).wait
    end
  end
end
