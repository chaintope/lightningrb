# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Feature do
  describe '#option_data_loss_protect?' do
    it { expect(Lightning::Feature.new('01').option_data_loss_protect?).to eq true }
    it { expect(Lightning::Feature.new('02').option_data_loss_protect?).to eq true }
    it { expect(Lightning::Feature.new('04').option_data_loss_protect?).to eq false }
  end

  describe '#initial_routing_sync?' do
    it { expect(Lightning::Feature.new('04').initial_routing_sync?).to eq false }
    it { expect(Lightning::Feature.new('08').initial_routing_sync?).to eq true }
    it { expect(Lightning::Feature.new('10').initial_routing_sync?).to eq false }
  end

  describe '#option_upfront_shutdown_script?' do
    it { expect(Lightning::Feature.new('10').option_upfront_shutdown_script?).to eq true }
    it { expect(Lightning::Feature.new('20').option_upfront_shutdown_script?).to eq true }
    it { expect(Lightning::Feature.new('40').option_upfront_shutdown_script?).to eq false }
  end

  describe '#gossip_queries?' do
    it { expect(Lightning::Feature.new('40').gossip_queries?).to eq true }
    it { expect(Lightning::Feature.new('80').gossip_queries?).to eq true }
    it { expect(Lightning::Feature.new('0100').gossip_queries?).to eq false }
  end

  describe '#valid?' do
    # The 2nd bits(even) of '14' is unknown, since there is no even bit for initial_routing_sync
    it { expect(Lightning::Feature.new('14').valid?).to eq false }

    # The 8th bits of '0141' is unknown
    it { expect(Lightning::Feature.new('0141').valid?).to eq false }

    # The 9th bits of '0200' is unknown, but it is optional bit
    it { expect(Lightning::Feature.new('0200').valid?).to eq true }
  end
end
