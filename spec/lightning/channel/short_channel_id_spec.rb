# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ShortChannelId do
  describe '#human_readable' do
    subject { described_class.new(block_height: 508000, tx_index: 2, output_index: 7) }
    it { expect(subject.human_readable).to eq '508000x2x7' }
  end

  describe '#to_i' do
    it { expect(described_class.new(block_height: 0, tx_index: 0, output_index: 0).to_i).to eq 0 }
    it { expect(described_class.new(block_height: 42_000, tx_index: 27, output_index: 3).to_i).to eq 0x0000a41000001b0003 }
    it { expect(described_class.new(block_height: 1_258_612, tx_index: 63, output_index: 0).to_i).to eq 0x13347400003f0000 }
    it { expect(described_class.new(block_height: 0xffffff, tx_index: 0x000000, output_index: 0xffff).to_i).to eq 0xffffff000000ffff }
    it { expect(described_class.new(block_height: 0x000000, tx_index: 0xffffff, output_index: 0xffff).to_i).to eq 0x000000ffffffffff }
    it { expect(described_class.new(block_height: 0xffffff, tx_index: 0xffffff, output_index: 0x0000).to_i).to eq 0xffffffffffff0000 }
    it { expect(described_class.new(block_height: 0xffffff, tx_index: 0xffffff, output_index: 0xffff).to_i).to eq 0xffffffffffffffff }
  end

  describe '.parse' do
    it { expect(described_class.parse(0).inspect).to eq "0x0x0" }
    it { expect(described_class.parse(0x0000a41000001b0003).inspect).to eq "42000x27x3"}
    it { expect(described_class.parse(0x13347400003f0000).inspect).to eq "1258612x63x0"}
    it { expect(described_class.parse(0xffffff000000ffff).inspect).to eq "16777215x0x65535" }
    it { expect(described_class.parse(0x000000ffffffffff).inspect).to eq "0x16777215x65535" }
    it { expect(described_class.parse(0xffffffffffff0000).inspect).to eq "16777215x16777215x0" }
    it { expect(described_class.parse(0xffffffffffffffff).inspect).to eq "16777215x16777215x65535" }
  end

  describe '#in?' do
    subject { described_class.new(block_height: 508000, tx_index: 2, output_index: 7) }

    it { expect(subject.in?(508000, 10)).to be_truthy }
    it { expect(subject.in?(508001, 10)).to be_falsy }
    it { expect(subject.in?(507990, 10)).to be_falsy }
    it { expect(subject.in?(507991, 10)).to be_truthy }
  end
end