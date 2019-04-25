# frozen_string_literal: true

require 'spec_helper'

describe Lightning::IO::Switchboard do
  let(:switchboard) { Lightning::IO::Switchboard.spawn(:switchboard, authenticator, context) }
  let(:authenticator) { spawn_dummy_actor(name: :authenticator) }
  let(:transport) { spawn_dummy_actor(name: :transport) }
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

    context 'with Disconnect' do
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

      it { expect(subject).to be_empty }
    end
  end
end

