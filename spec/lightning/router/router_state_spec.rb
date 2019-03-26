# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::RouterState do
  describe '#next' do
    subject { state.next(message, data) }

    let(:state) { Lightning::Router::RouterState::Normal.new(router, context) }
    let(:router) { Lightning::Router::Router.new(context) }
    let(:context) { build(:context) }
    let(:data) { Lightning::Router::Messages::Data[nodes, channels, updates, query_channel_ranges, query_short_channel_ids] }
    let(:nodes) { {} }
    let(:channels) { {} }
    let(:updates) { {} }
    let(:query_channel_ranges) { {} }
    let(:query_short_channel_ids) { {} }

    context 'with NodeAnnouncement message' do
      let(:message) { build(:node_announcement) }
      let(:remote_node_id) { build(:key, :remote_funding_pubkey).pubkey }

      it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
      it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }

      context 'upon receiving a new node_announcement with an updated timestamp' do
        let(:nodes) { { remote_node_id => build(:node_announcement, timestamp: 100_000_000) } }
        let(:message) { build(:node_announcement, timestamp: 100_000_001) }

        it 'SHOULD update its local view of the network\'s topology accordingly.' do
          expect(subject[1][:nodes][remote_node_id].timestamp).to eq 100_000_001
        end
      end

      context 'otherwise' do
        let(:nodes) { { remote_node_id => build(:node_announcement, timestamp: 100_000_000) } }
        let(:message) { build(:node_announcement, timestamp: 99_999_999) }

        it 'do not update its local view of the network\'s topology.' do
          expect(subject[1][:nodes][remote_node_id].timestamp).to eq 100_000_000
        end
      end
    end

    context 'with ChannelUpdate' do
      let(:message) { build(:channel_update, short_channel_id: 1) }
      let(:channel) { build(:channel_announcement, short_channel_id: 1) }
      let(:desc) { Lightning::Router::Announcements.to_channel_desc(channel) }
      let(:channels) { { channel.short_channel_id => channel } }

      it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
      it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }

      context 'upon receiving a new channel_update with an updated timestamp' do
        let(:updates) { { desc => build(:channel_update, timestamp: 100_000_000) } }
        let(:message) { build(:channel_update, timestamp: 100_000_001) }

        it 'SHOULD update its local view of the network\'s topology accordingly.' do
          expect(subject[1][:updates][desc].timestamp).to eq 100_000_001
        end
      end

      context 'otherwise' do
        let(:updates) { { desc => build(:channel_update, timestamp: 100_000_000) } }
        let(:message) { build(:channel_update, timestamp: 99_999_999) }

        it 'do not update its local view of the network\'s topology.' do
          expect(subject[1][:updates][desc].timestamp).to eq 100_000_000
        end
      end
    end

    context 'with RequestGossipQuery' do
      let(:transport) { spawn_dummy_actor }
      let(:remote_node_id) { '00' * 32 }
      let(:message) { Lightning::Router::Messages::RequestGossipQuery.new(transport, remote_node_id) }

      it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
      it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
      it do
        expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::GossipTimestampFilter)
        expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::QueryChannelRange)
        subject
      end
    end

    context 'with QueryMessage' do
      let(:transport) { spawn_dummy_actor }
      let(:remote_node_id) { '00' * 32 }
      let(:message) do
        Lightning::Router::Messages::QueryMessage.new(transport, remote_node_id, query)
      end
      let(:channels) { { 1099511758851 => build(:channel_announcement, node_id_1: '11' * 32, node_id_2: '22' * 32) } }
      let(:updates) { { Lightning::Router::Messages::ChannelDesc[0, '11' * 32, '22' * 32] => build(:channel_update) } }

      context 'QueryChannelRange' do
        let(:query) do
          Lightning::Wire::LightningMessages::QueryChannelRange.new(
            chain_hash: '00' * 32,
            first_blocknum: 1,
            number_of_blocks: number_of_blocks
          )
        end
        let(:number_of_blocks) { 1000 }

        it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
        it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
        it do
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ReplyChannelRange)
          subject
        end

        context 'if has channel which is out of ranges' do
          let(:channels) { { 1100611139534851 => build(:channel_announcement) } }
          it do
            expect(transport).not_to receive(:<<).with(Lightning::Wire::LightningMessages::ReplyChannelRange)
            subject
          end
        end

        context 'if has 8001 channels' do
          let(:number_of_blocks) { 10000 }
          let(:channels) do
            (0...8001).map do |i|
              [Lightning::Channel::ShortChannelId.new(block_height: 1, tx_index: i, output_index: 0).to_i, build(:channel_announcement)]
            end.to_h
          end

          it do
            expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ReplyChannelRange).twice
            subject
          end
        end
      end

      context 'QueryShortChannelIds' do
        let(:query) do
          Lightning::Wire::LightningMessages::QueryShortChannelIds.new(
            chain_hash: '00' * 32,
            encoded_short_ids: '0000000100000200030000010000020004'
          )
        end

        it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
        it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
        it do
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ChannelAnnouncement)
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ChannelUpdate)
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ReplyShortChannelIdsEnd)
          subject
        end
      end

      context 'ReplyChannelRange' do
        let(:query) do
          Lightning::Wire::LightningMessages::ReplyChannelRange.new(
            chain_hash: '00' * 32,
            first_blocknum: 1,
            number_of_blocks: 1000,
            complete: 1,
            encoded_short_ids: '00111111111111111122222222222222223333333333333333'
          )
        end
        let(:query_channel_ranges) { { remote_node_id => true } }
        let(:query_short_channel_ids) { { remote_node_id => false } }

        it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
        it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
        it do
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::QueryShortChannelIds)
          subject
        end
        it do
          subject
          expect(data[:query_channel_ranges][remote_node_id]).to be_falsy
          expect(data[:query_short_channel_ids][remote_node_id]).to be_truthy
        end
      end

      context 'ReplyShortChannelIdsEnd' do
        let(:query) do
          Lightning::Wire::LightningMessages::ReplyShortChannelIdsEnd.new(
            chain_hash: '00' * 32,
            complete: 1
          )
        end
        let(:query_short_channel_ids) { { remote_node_id => true } }

        it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
        it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
        it do
          subject
          expect(data[:query_short_channel_ids][remote_node_id]).to be_falsy
        end
      end
    end
  end
end
