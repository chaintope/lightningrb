# frozen_string_literal: true

require 'lightning/channel/short_channel_id.pb'

module Lightning
  module Channel
    class ShortChannelId < Lightning::Channel::Generated::ShortChannelId
      include Lightning::Wire::Serialization
      extend Lightning::Wire::Serialization

      def encode
        [to_i].pack('q>')
      end

      def self.decode_from(payload)
        block_height, tx_index, output_index = parse(payload.read(8).unpack('q>').first)
        new(block_height: block_height, tx_index: tx_index, output_index: output_index)
      end

      def self.parse(short_channel_id)
        [(short_channel_id >> 40) & 0xFFFFFF, (short_channel_id >> 16) & 0xFFFFFF, short_channel_id & 0xFFFF]
      end

      def to_i
        ((block_height & 0xFFFFFF) << 40) | ((tx_index & 0xFFFFFF) << 16) | (output_index & 0xFFFF)
      end

      def inspect
        human_readable
      end

      def human_readable
        "#{block_height}x#{tx_index}x#{output_index}"
      end
    end
  end
end
