# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::Channel do
  describe 'handler_error' do
    subject { channel.ask("unsupported_message") }

    let(:channel_context) { build(:channel_context) }
    let(:channel) { described_class.spawn(:channel, channel_context) }

    it do
      expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::ChannelFailed)
      subject
      channel_context.broadcast.ask(:await).wait
      channel.ask(:await).wait
    end
  end

  describe '.to_channel_id' do
    vector =
      [
        {
          txid: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          output_index: 0,
          expected: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        }, {
          txid: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          output_index: 1,
          expected: 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe',
        }, {
          txid: '0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          output_index: 2,
          expected: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0002',
        }, {
          txid: 'f000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          output_index: 0x0F00,
          expected: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0ff0',
        },
      ]
    vector.each.with_index do |data, i|
      context "test #{i}" do
        subject { Lightning::Channel::Channel.to_channel_id(data[:txid], data[:output_index]) }

        it { is_expected.to eq data[:expected] }
      end
    end
  end

  describe '.to_short_id' do
    it { expect(described_class.to_short_id(0, 0, 0)).to eq 0 }
    it { expect(described_class.to_short_id(42_000, 27, 3)).to eq 0x0000a41000001b0003 }
    it { expect(described_class.to_short_id(1_258_612, 63, 0)).to eq 0x13347400003f0000 }
    it { expect(described_class.to_short_id(0xffffff, 0x000000, 0xffff)).to eq 0xffffff000000ffff }
    it { expect(described_class.to_short_id(0x000000, 0xffffff, 0xffff)).to eq 0x000000ffffffffff }
    it { expect(described_class.to_short_id(0xffffff, 0xffffff, 0x0000)).to eq 0xffffffffffff0000 }
    it { expect(described_class.to_short_id(0xffffff, 0xffffff, 0xffff)).to eq 0xffffffffffffffff }
  end
end
