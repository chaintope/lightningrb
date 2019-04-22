# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Switchboard do
  let(:switchboard) { Lightning::IO::Switchboard.spawn(:switchboard, authenticator, context) }
  let(:authenticator) { spawn_dummy_actor(name: :authenticator) }
  let(:transport) { spawn_dummy_actor(name: :transport) }
  let(:context) { build(:context) }

  describe 'on_message' do
    context 'with Authenticated' do
      subject do
        switchboard << Lightning::IO::AuthenticateMessages::Authenticated[conn, transport, '00' * 32]
        switchboard.ask(:await).wait
      end

      let(:client) { spawn_dummy_actor(name: :client) }
      let(:conn) { Lightning::IO::ClientConnection.new(nil, '192.168.1.16', 7359, {}) }

      it { expect { subject }.to change { context.peer_db.all.size }.by(1) }
    end

    context 'with Disconnect' do
      subject do
        switchboard << Lightning::IO::PeerEvents::Disconnect['00' * 32]
        switchboard.ask(:await).wait
        switchboard.ask!(:peers)
      end

      before do
        allow(Lightning::IO::Client).to receive(:connect).and_return(nil)
        switchboard << Lightning::IO::AuthenticateMessages::Authenticated[{}, transport, '00' * 32]
        switchboard.ask(:await).wait
      end

      it { expect(subject).to be_empty }
    end
  end
end

