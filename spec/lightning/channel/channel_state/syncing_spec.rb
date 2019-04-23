# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::Syncing do
  let(:state) { described_class.new(channel, channel_context) }
  let(:ln_context) { Lightning::Context.new(spv) }
  let(:channel_context) { Lightning::Channel::ChannelContext.new(ln_context, forwarder, remote_node_id) }
  let(:channel) { DummyActor.spawn(:channel) }
  let(:forwarder) { DummyActor.spawn(:forwarder) }
  let(:remote_node_id) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
  let(:spv) { create_test_spv }

  describe '#message' do
    subject { state.next(message, data) }

    let(:message) { build(:channel_reestablish) }

    context 'wait for funding confirmed' do
      let(:data) { build(:data_wait_for_funding_confirmed).get }

      it do
        expect(ln_context.blockchain).to receive(:<<).with(Lightning::Blockchain::Messages::WatchConfirmed)
        subject
        ln_context.blockchain.ask(:await).wait
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingConfirmed }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingConfirmed }
    end

    context 'wait for funding locked' do
      let(:data) { build(:data_wait_for_funding_locked).get }

      it do
        expect(ln_context.blockchain).to receive(:<<).with(Lightning::Blockchain::Messages::WatchConfirmed)
        subject
        ln_context.blockchain.ask(:await).wait
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::WaitForFundingLocked }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataWaitForFundingLocked }
    end

    context 'normal' do
      let(:data) { build(:data_normal).get }

      it do
        expect(ln_context.blockchain).to receive(:<<).with(Lightning::Blockchain::Messages::WatchConfirmed)
        subject
        ln_context.blockchain.ask(:await).wait
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }

      context 'buried' do
        let(:data) { build(:data_normal, buried: 1).get }

        it do
          expect(ln_context.blockchain).not_to receive(:<<).with(Lightning::Blockchain::Messages::WatchConfirmed)
          subject
          ln_context.blockchain.ask(:await).wait
        end
      end
    end
  end
end
