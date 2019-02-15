# frozen_string_literal: true

require 'spec_helper'

describe Concurrent::Actor::Reference do
  let(:actor) { spawn_dummy_actor(name: :dummy) }

  describe '#perform_later' do
    it do
      expect(actor).to receive(:<<).with(:test)
      actor.perform_later(:test)
      sleep(6)
      actor.ask(:await).wait
    end
  end
end
