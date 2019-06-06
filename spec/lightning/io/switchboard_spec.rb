# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Switchboard do
  class DummyTransport < Concurrent::Actor::Context
    include Lightning::Wire::HandshakeMessages
    def on_message(message)
      case message
      when Listener
        @listener = message[:listener]
      when Lightning::Wire::LightningMessages::Init
        @listener << message
      end
    end
  end

  let(:switchboard) { Lightning::IO::Switchboard.spawn(:switchboard, authenticator, context) }
  let(:authenticator) { spawn_dummy_actor(name: :authenticator) }
  let(:transport) { DummyTransport.spawn(:transport) }
  let(:context) { build(:context) }
  let(:session) { spawn_dummy_actor(name: :client) }


  before do
    allow(Lightning::IO::ClientSession).to receive(:connect).and_return(nil)
  end

  describe 'on_message' do
    context 'with Authenticated' do
      subject do
        switchboard << Lightning::IO::PeerEvents::Connect['00' * 32, 'localhost', 9735]
        switchboard << Lightning::IO::AuthenticateMessages::Authenticated[session, transport, '00' * 32]
        switchboard.ask(:await).wait
      end

      it { expect { subject }.to change { context.peer_db.all.size }.by(1) }
    end

    context 'with Unauthenticated' do
      subject do
        switchboard << Lightning::IO::AuthenticateMessages::Unauthenticated['00' * 32]
        switchboard.ask(:await).wait
        switchboard.ask!(:peers)
      end

      before do
        switchboard << Lightning::IO::PeerEvents::Connect['00' * 32, 'localhost', 9735]
        switchboard << Lightning::IO::AuthenticateMessages::Authenticated[session, transport, '00' * 32]
        switchboard.ask(:await).wait
      end

      it { expect(subject.size).to eq 1 }
    end

    context 'with Lightning::Grpc::ListChannelsRequest' do
      subject { switchboard.ask!(Lightning::Grpc::ListChannelsRequest.new) }

      it { is_expected.to be_empty }

      context 'has channel' do
        let(:data) { build(:data_normal).get }
        let(:init) { build(:init) }
        let(:expected) do
          {
            channel_id: '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff',
            short_channel_id: 1,
            status: 'opening',
            temporary_channel_id: '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357',
            to_local_msat: 7_000_000_000,
            to_remote_msat: 3_000_000_000,
            local_node_id: '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa',
            remote_node_id: '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7'
          }
        end
        before do
          context.channel_db.insert_or_update(data)

          switchboard << Lightning::IO::PeerEvents::Connect[
            '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7', 'localhost', 9735
          ]
          switchboard << Lightning::IO::AuthenticateMessages::Authenticated[
            session, transport, '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7'
          ]
          switchboard.ask(:await).wait
          sleep(1) # to make peer 'connected'.
          transport << init
          transport.ask(:await).wait
          switchboard.ask(:await).wait
        end

        it { is_expected.to eq [expected] }
      end
    end
  end
end
