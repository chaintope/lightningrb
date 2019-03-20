# frozen_string_literal: true

require 'zlib'

module Lightning
  module Router
    class Queries
      ENCODE_TYPE_UNCOMPRESSED = 0
      ENCODE_TYPE_ZLIB = 1

      # @param short_channel_ids Array of Lightning::Channel::ShortChannelId
      def self.encode_short_channel_ids(encode_type, short_channel_ids)
        short_channel_ids = short_channel_ids.map(&:to_i).sort
        encoded = case encode_type
        when ENCODE_TYPE_UNCOMPRESSED
          short_channel_ids.pack('q>*')
        when ENCODE_TYPE_ZLIB
          Zlib::Deflate.deflate(short_channel_ids.pack('q>*'), Zlib::DEFAULT_COMPRESSION)
        else
          raise "unknown type: #{encode_type}"
        end
        ([encode_type].pack('C') + encoded).bth
      end

      # @return short_channel_ids Array of Lightning::Channel::ShortChannelId
      def self.decode_short_channel_ids(encoded_short_channel_ids)
        encode_type, encoded_short_channel_ids = encoded_short_channel_ids.htb.unpack('Ca*')
        decoded = case encode_type
        when ENCODE_TYPE_UNCOMPRESSED
          encoded_short_channel_ids
        when ENCODE_TYPE_ZLIB
          decoded = Zlib::Inflate.inflate(encoded_short_channel_ids)
          decoded
        else
          raise "unknown type: #{encode_type}"
        end
        stream = StringIO.new(decoded)
        short_channel_ids = []
        until stream.eof
          short_channel_ids << Lightning::Channel::ShortChannelId.decode_from(stream)
        end
        short_channel_ids
      end

      # @param short_channel_ids Array of Lightning::Channel::ShortChannelId
      def self.make_query_short_channel_ids(node_params, short_channel_ids, encode_type = ENCODE_TYPE_UNCOMPRESSED)
        encoded = encode_short_channel_ids(encode_type, short_channel_ids)
        Lightning::Wire::LightningMessages::QueryShortChannelIds.new(
          chain_hash: node_params.chain_hash,
          encoded_short_ids: encoded
        )
      end

      def self.make_reply_short_channel_ids_end(query_short_channel_ids)
        Lightning::Wire::LightningMessages::ReplyShortChannelIdsEnd.new(
          chain_hash: query_short_channel_ids.chain_hash,
          complete: 1
        )
      end

      def self.make_query_channel_range(node_params, first_blocknum = 0, number_of_blocks = (1 << 32) - 1)
        Lightning::Wire::LightningMessages::QueryChannelRange.new(
          chain_hash: node_params.chain_hash,
          first_blocknum: first_blocknum,
          number_of_blocks: number_of_blocks
        )
      end

      # @param short_channel_ids Array of Lightning::Channel::ShortChannelId
      def self.make_reply_channel_range(query_channel_range, short_channel_ids, encode_type = ENCODE_TYPE_UNCOMPRESSED)
        short_channel_ids = short_channel_ids.select do |short_channel_id|
          short_channel_id.in?(query_channel_range.first_blocknum, query_channel_range.number_of_blocks)
        end
        first_block = short_channel_ids.first.block_height
        last_block = short_channel_ids.last.block_height
        encoded = encode_short_channel_ids(encode_type, short_channel_ids)
        Lightning::Wire::LightningMessages::ReplyChannelRange.new(
          chain_hash: query_channel_range.chain_hash,
          first_blocknum: first_block,
          number_of_blocks: last_block - first_block + 1,
          complete: 1,
          encoded_short_ids: encoded
        )
      end

      def self.make_gossip_timestamp_filter(node_params, first_timestamp = Time.now.to_i, timestamp_range = (1 << 32) - 1)
        Lightning::Wire::LightningMessages::GossipTimestampFilter.new(
          chain_hash: node_params.chain_hash,
          first_timestamp: first_timestamp,
          timestamp_range: timestamp_range
        )
      end

      def self.filter_gossip_messages(messages, filter)
        return messages unless filter
        messages.select { |message| filter.match?(message) }
      end
    end
  end
end
