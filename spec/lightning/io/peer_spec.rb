# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Peer do
  let(:peer) { build(:peer) }

  describe 'on_message' do
    context 'state is Disconnect' do
      describe 'with Connect' do
        it do
          expect(Lightning::IO::Client).to receive(:connect).and_return(nil)
          peer << Lightning::IO::PeerEvents::Connect['00' * 32, 'localhost', 9735]
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateDisconnected'
        end
      end

      describe 'with Authenticated' do
        let(:transport) { spawn_dummy_actor(name: :transport) }
        it do
          peer << Lightning::IO::AuthenticateMessages::Authenticated[{}, transport, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7']
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateInitializing'
        end
      end
    end

    context 'state is Initializing' do
      let(:transport) { spawn_dummy_actor(name: :transport) }
      before do
        peer << Lightning::IO::AuthenticateMessages::Authenticated[{}, transport, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7']
        peer.ask(:await).wait
      end

      describe 'with Init' do
        let(:init) { build(:init).get }
        it do
          peer << init
          peer.ask(:await).wait
          expect(peer.ask!(:status)).to eq 'Lightning::IO::Peer::PeerStateConnected'
        end
      end
    end

    context 'state is Connected' do
      let(:transport) { spawn_dummy_actor(name: :transport) }
      let(:init)  { build(:init).get }
      before do
        peer << Lightning::IO::AuthenticateMessages::Authenticated[{}, transport, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7']
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
          peer << Lightning::Wire::LightningMessages::Ping[100, 10, '01010101010101010101']
          peer.ask(:await).wait
        end
      end

      describe 'with OpenChannel' do
        subject do
          peer << open_channel
          peer.ask(:await).wait
        end

        let(:open_channel) { Lightning::IO::PeerEvents::OpenChannel['00' * 32, 10_000_000, 10_000, 1, {}] }

        it 'add channel' do
          expect { subject }.to change { peer.ask!(:channels).size }.by(1)
        end
      end

      describe 'with HasTemporaryChannelId(AcceptChannel)' do
        subject do
          peer << accept
          peer.ask(:await).wait
        end

        let(:accept) { build(:accept_channel).get }

        it { expect { subject }.not_to raise_error }
      end

      describe 'with HasChannelId(UpdateAddHtlc)' do
        subject do
          peer << update_add_htlc
          peer.ask(:await).wait
        end

        let(:update_add_htlc) { build(:update_add_htlc).get }

        it { expect { subject }.not_to raise_error }
      end

      describe 'with ChannelIdAssigned' do
        subject do
          peer << Lightning::Channel::Events::ChannelIdAssigned[channel, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7', '00' * 32, '11' * 32]
          peer.ask(:await).wait
        end

        let(:channel) { spawn_dummy_actor(name: :channel) }

        it 'add channel' do
          expect { subject }.to change { peer.ask!(:channels).size }.by(1)
        end
      end
    end
  end
end
