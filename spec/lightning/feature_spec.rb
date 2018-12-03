# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Feature do
  describe '.initial_routing_sync?' do
    it { expect(Lightning::Feature.initial_routing_sync?('08')).to eq true }
  end
  describe '.supported?' do
    it { expect(Lightning::Feature.supported?('0400000000000000')).to eq false }
    it { expect(Lightning::Feature.supported?('0800000000000000')).to eq true }
    it { expect(Lightning::Feature.supported?('14')).to eq false }
    it { expect(Lightning::Feature.supported?('0141')).to eq false }
  end
end
