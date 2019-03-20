# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::RouterState do
  describe '#next' do
    subject { state.next(message, data) }

    let(:state) { Lightning::Router::RouterState::Normal.new(router, context) }
    let(:router) { Lightning::Router::Router.new(context) }
    let(:context) { build(:context) }
    let(:data) { Lightning::Router::Messages::Data[nodes, channels, updates] }
    let(:nodes) { {} }
    let(:channels) { {} }
    let(:updates) { {} }

    context 'with NodeAnnouncement message' do
      let(:message) { build(:node_announcement) }

      it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
      it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
    end

    context 'with RequestGossipQuery' do
      let(:transport) { spawn_dummy_actor }
      let(:message) { Lightning::Router::Messages::RequestGossipQuery.new(conn: transport) }

      it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
      it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
      it do
        expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::GossipTimestampFilter)
        expect(transport).to receive(:<<).with(Lightning::Wire::LightningMessages::QueryChannelRange)
        subject
      end
    end
  end
end
