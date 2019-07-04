# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Peer do
  let(:peer) { build(:peer, context: ln_context) }
  let(:transport) { spawn_dummy_actor(name: :transport) }
  let(:client) { spawn_dummy_actor(name: :transport) }
  let(:authenticated) { Lightning::IO::AuthenticateMessages::Authenticated[client, transport, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7'] }
  let(:ln_context) { build(:context) }

  describe 'initialize_stored_channels' do
    subject { Lightning::IO::Peer::PeerStateInitializing.new(authenticator, ln_context, '00' * 33).initialize_stored_channels(ln_context, '00' * 33) }

    let(:authenticator) { spawn_dummy_actor(name: :transport) }
    let(:this_remote_param) { build(:remote_param, node_id: '00' * 33).get }
    let(:other_remote_param) { build(:remote_param, node_id: '11' * 33).get }

    let(:this_peer_channel) { build(:data_normal, commitments: build(:commitment, channel_id: '22' * 32, remote_param: this_remote_param).get).get }
    let(:other_peer_channel) { build(:data_normal, commitments: build(:commitment, channel_id: '33' * 32, remote_param: other_remote_param).get).get }

    before do
      ln_context.channel_db.insert_or_update(this_peer_channel)
      ln_context.channel_db.insert_or_update(other_peer_channel)
    end

    it do
      expect(subject.size).to eq 1
      expect(subject.first.channel_id).to eq this_peer_channel.channel_id
    end
  end

  describe 'on_message' do
    context 'state is Disconnect' do
      describe 'with Connect' do
        it do
          expect(Lightning::IO::ClientSession).to receive(:connect).and_return(nil)
          peer << Lightning::IO::PeerEvents::Connect['00' * 32, 'localhost', 9735]
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateDisconnected'
        end
      end

      describe 'with Authenticated' do

        it do
          peer << authenticated
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateInitializing'
        end
      end
    end

    context 'state is Initializing' do
      let(:transport) { spawn_dummy_actor(name: :transport) }
      let(:client) { spawn_dummy_actor(name: :transport) }

      before do
        peer << authenticated
        peer.ask(:await).wait
      end

      describe 'with Init' do
        let(:init) { build(:init) }
        it do
          peer << init
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateConnected'
        end

        context 'when features are not supported' do
          subject do
            peer << init
            peer.ask(:await).wait
          end

          let(:init) { build(:init, localfeatures: '0141') }

          it do
            expect(client).to receive(:<<).with(:close)
            subject
          end
        end
      end
    end

    context 'state is Connected' do
      let(:transport) { spawn_dummy_actor(name: :transport) }
      let(:init)  { build(:init) }
      before do
        peer << authenticated
        peer.ask(:await).wait
        peer << init
        peer.ask(:await).wait
      end

      describe 'with Timeout' do
        it 'ping to other node' do
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::Ping)
          peer << Lightning::IO::PeerEvents::Timeout
          peer.ask(:await).wait
        end
      end

      describe 'with Ping' do
        it 'respond with Pong' do
          expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::Pong)
          peer << Lightning::Wire::LightningMessages::Ping.new(num_pong_bytes: 100, ignored: '01010101010101010101')
          peer.ask(:await).wait
        end
      end

      describe 'with OpenChannel' do
        subject do
          peer << open_channel
          peer.ask(:await).wait
        end

        let(:open_channel) { Lightning::IO::PeerEvents::OpenChannel['00' * 32, 10_000_000, 10_000, 1, ''] }

        it 'add channel' do
          expect { subject }.to change { peer.ask!(:channels).size }.by(1)
        end
      end

      describe 'with HasTemporaryChannelId(AcceptChannel)' do
        subject do
          peer << accept
          peer.ask(:await).wait
        end

        let(:accept) { build(:accept_channel) }

        it { expect { subject }.not_to raise_error }
      end

      describe 'with HasChannelId(UpdateAddHtlc)' do
        subject do
          peer << update_add_htlc
          peer.ask(:await).wait
        end

        let(:update_add_htlc) { build(:update_add_htlc) }

        it { expect { subject }.not_to raise_error }
      end

      describe 'with ChannelIdAssigned' do
        subject do
          peer << Lightning::Channel::Events::ChannelIdAssigned.build(channel,
            remote_node_id: '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7',
            temporary_channel_id: '00' * 32,
            channel_id: '11' * 32
          )
          peer.ask(:await).wait
        end

        let(:channel) { spawn_dummy_actor(name: :channel) }

        it 'add channel' do
          expect { subject }.to change { peer.ask!(:channels).size }.by(1)
        end
      end

      describe 'with QueryChannelRange' do
        subject do
          peer << Lightning::Wire::LightningMessages::QueryChannelRange.new(
            chain_hash: '00' * 32,
            first_blocknum: 100,
            number_of_blocks: 200
          )
          peer.ask(:await).wait
        end

        let(:peer) { build(:peer, context: context) }
        let(:context) { build(:context) }

        it do
          expect(context.router).to receive(:<<).with(Lightning::Router::Messages::QueryMessage)
          subject
        end
      end

      describe 'with Rebroadcast' do
        subject do
          peer << Lightning::Wire::LightningMessages::GossipTimestampFilter.new(
            chain_hash: '00' * 32,
            first_timestamp: 1_552_905_069,
            timestamp_range: 1 << 31
          )
          peer.ask(:await).wait
          peer << Lightning::Router::Messages::Rebroadcast[message: message]
          peer.ask(:await).wait
        end

        context 'gossip_timestamp_filter is set' do
          let(:message) { build(:channel_update, timestamp: 1_552_905_069) }

          it do
            expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::ChannelUpdate)
            subject
          end

          context 'timestamp is expired' do
            let(:message) { build(:channel_update, timestamp: 1_552_905_068) }
            it do
              expect(transport).not_to receive(:<<).with(Lightning::Wire::LightningMessages::ChannelUpdate)
              subject
            end
          end
        end
      end
    end
  end
end
