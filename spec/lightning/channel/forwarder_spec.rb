# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::Forwarder do
  let(:actor) { spawn_dummy_actor }
  let(:forwarder) { described_class.spawn(:subject) }
  let(:message) { Lightning::Wire::LightningMessages::Init.new(globalfeatures: '', localfeatures: '') }

  describe 'on_message(LightningMessage)' do
    subject do
      forwarder << message
      forwarder.ask(:await).wait
    end

    context 'destination is test actor' do
      before { forwarder << actor }
      it 'forward message' do
        expect(actor).to receive(:<<).with(message)
        subject
      end
    end

    context 'no destination' do
      it 'does not forward message' do
        expect(actor).not_to receive(:<<)
        subject
      end
    end
  end
end
