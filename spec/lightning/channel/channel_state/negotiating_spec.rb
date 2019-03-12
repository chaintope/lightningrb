# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::Negotiating do
  let(:state) { described_class.new(channel, channel_context) }
  let(:ln_context) { Lightning::Context.new(spv) }
  let(:channel_context) { Lightning::Channel::ChannelContext.new(ln_context, forwarder, remote_node_id) }
  let(:channel) { DummyActor.spawn(:channel) }
  let(:forwarder) { DummyActor.spawn(:forwarder) }
  let(:remote_node_id) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
  let(:spv) { create_test_spv }

  describe '#message' do
    subject { state.next(message, data) }

    before { spv.stub(:broadcast).and_return(nil) }

    context 'remote fee met local' do
      let(:message) { build(:closing_signed) }
      let(:tx) { Bitcoin::Tx.new }
      let(:commitment) { build(:commitment, :funder).get }
      let(:data) do
        Lightning::Channel::Messages::DataNegotiating[
          commitment,
          build(:shutdown),
          build(:shutdown),
          [Lightning::Channel::Messages::ClosingTxProposed[tx, build(:closing_signed)]],
          Algebrick::None
        ]
      end

      before { allow(Lightning::Transactions::Closing).to receive(:valid_signature?).and_return(tx) }

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Closing }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataClosing }
    end
  end
end
