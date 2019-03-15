# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::Queries do
  let(:short_channel_ids) do
    [
      Lightning::Channel::ShortChannelId.new(block_height: 503788, tx_index: 275, output_index: 0),
      Lightning::Channel::ShortChannelId.new(block_height: 503816, tx_index: 1343, output_index: 1),
      Lightning::Channel::ShortChannelId.new(block_height: 504279, tx_index: 885, output_index: 1),
    ]
  end
  let(:encoded_short_ids) { '0007afec000113000007b00800053f000107b1d70003750001' }

  describe '.encode_short_channel_ids' do
    subject { described_class.encode_short_channel_ids(encode_type, short_channel_ids) }

    let(:encode_type) { Lightning::Router::Queries::ENCODE_TYPE_UNCOMPRESSED }

    it { expect(subject).to eq encoded_short_ids }
  end

  describe '.decode_short_channel_ids' do
    subject { described_class.decode_short_channel_ids(encoded_short_ids) }

    it { expect(subject).to eq short_channel_ids }
  end

  describe '.make_query_short_channel_ids' do
    subject { described_class.make_query_short_channel_ids(node_params, short_channel_ids) }

    let(:node_params) { build(:node_param) }

    it { expect(subject.chain_hash).to eq 'ff' * 32 }
    it { expect(subject.encoded_short_ids).to eq encoded_short_ids }
  end

  describe '.make_reply_short_channel_ids_end' do
    subject { described_class.make_reply_short_channel_ids_end(query_short_channel_ids) }

    let(:query_short_channel_ids) do
      Lightning::Wire::LightningMessages::QueryShortChannelIds.new(
        chain_hash: 'ff' * 32,
        encoded_short_ids: encoded_short_ids
      )
    end

    it { expect(subject.chain_hash).to eq 'ff' * 32 }
    it { expect(subject.complete).to eq 1 }
  end

  describe '.make_query_channel_range' do
    subject { described_class.make_query_channel_range(node_params, first_blocknum, number_of_blocks) }

    let(:node_params) { build(:node_param) }
    let(:first_blocknum) { 100 }
    let(:number_of_blocks) { 9999 }

    it { expect(subject.chain_hash).to eq 'ff' * 32 }
    it { expect(subject.first_blocknum).to eq 100 }
    it { expect(subject.number_of_blocks).to eq 9_999}
  end

  describe '.make_reply_channel_range' do
    subject { described_class.make_reply_channel_range(query_channel_range, short_channel_ids) }

    let(:query_channel_range) do
      Lightning::Wire::LightningMessages::QueryChannelRange.new(
        chain_hash: 'ff' * 32,
        first_blocknum: 0,
        number_of_blocks: 4294967295
      )
    end

    it { expect(subject.chain_hash).to eq 'ff' * 32 }
    it { expect(subject.first_blocknum).to eq 503788 }
    it { expect(subject.number_of_blocks).to eq 492 }
    it { expect(subject.complete).to eq 1 }
    it { expect(subject.encoded_short_ids).to eq encoded_short_ids }
  end

  describe '.make_gossip_timestamp_filter' do
    subject { described_class.make_gossip_timestamp_filter(node_params, first_timestamp) }

    let(:node_params) { build(:node_param) }
    let(:first_timestamp) { 1552566696 }

    it { expect(subject.chain_hash).to eq 'ff' * 32 }
    it { expect(subject.first_timestamp).to eq 1552566696 }
    it { expect(subject.timestamp_range).to eq 4294967295 }
  end

  describe '.filter_gossip_messages' do
    subject { described_class.filter_gossip_messages(messages, filter) }

    let(:messages) do
      [
        build(:channel_update, timestamp: 1552566695),
        build(:channel_update, timestamp: 1552566696),
        build(:channel_update, timestamp: 1552566697)
      ]
    end
    let(:filter) do
      Lightning::Wire::LightningMessages::GossipTimestampFilter.new(
        chain_hash: 'ff' * 32,
        first_timestamp: 1552566696,
        timestamp_range: 4294967295
      )
    end

    it { expect(subject.size).to eq 2 }
    it { expect(subject[0].timestamp).to eq 1552566696 }
    it { expect(subject[1].timestamp).to eq 1552566697 }
  end
end
