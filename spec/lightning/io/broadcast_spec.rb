# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Broadcast do
  class Receiver < Concurrent::Actor::Context
    def initialize(broadcast)
      broadcast << [:subscribe, Lightning::Wire::LightningMessages::Init]
    end

    def on_message(message)
    end
  end

  let(:receiver) { Receiver.spawn(:receiver, broadcast) }
  let(:broadcast) { build(:broadcast) }
  let(:message) { Lightning::Wire::LightningMessages::Init[0, '', 0, ''] }

  describe 'on_message(Init)' do
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
end
