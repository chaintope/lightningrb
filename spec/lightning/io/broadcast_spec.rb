# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Broadcast do
  class Receiver < Concurrent::Actor::Context
    def initialize(broadcast)
      broadcast << [:subscribe, Lightning::Wire::LightningMessages::Init]
      @broadcast = broadcast
    end

    def on_message(message)
      @broadcast.ask! message
    end
  end

  let(:receiver) { Receiver.spawn(:receiver, broadcast) }
  let(:broadcast) { build(:broadcast) }
  let(:message) { build(:init) }

  describe 'on_message(Init)' do
    context 'received Init message' do
      subject do
        receiver.ask(:await).wait
        broadcast.ask(:await).wait
        broadcast << message
        broadcast.ask(:await).wait
        receiver.ask(:await).wait
      end

      it do
        expect(receiver).to receive(:<<).with(message)
        subject
      end
    end

    context 'unsubscribe' do
      subject do
        receiver << :unsubscribe
        receiver.ask(:await).wait
      end

      it do
        receiver.ask(:await).wait
        expect(receiver.ask!([:subscribe?, Lightning::Wire::LightningMessages::Init])).to eq true
        subject
        expect(receiver.ask!([:subscribe?, Lightning::Wire::LightningMessages::Init])).to eq false
      end
    end
  end
end
