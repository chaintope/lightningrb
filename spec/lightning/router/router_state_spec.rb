# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::RouterState do
  # describe '#next' do
  #   subject do
  #     state.next(message, data)
  #   end
  #
  #   let(:state) { Lightning::Router::RouterState::Normal.new(router, context) }
  #   let(:router) { Lightning::Router::Router.new(context) }
  #   let(:context) { build(:context) }
  #   let(:data) { Lightning::Router::Messages::Data[nodes, channels, updates] }
  #   let(:nodes) { {} }
  #   let(:channels) { {} }
  #   let(:updates) { {} }
  #   #
  #   # context 'with NodeAnnouncement message' do
  #   #   let(:message) { build(:node_announcement).get }
  #   #
  #   #   it { expect(subject[0]).to be_a Lightning::Router::RouterState::Normal }
  #   #   it { expect(subject[1]).to be_a Lightning::Router::Messages::Data }
  #   #
  #   #   context 'when signature is invalid' do
  #   #
  #   #   end
  #   #
  #   #   context 'when node added' do
  #   #     let(:channel1) { build(:channel_announcement, short_channel_id: 1).get }
  #   #     let(:channel2) { build(:channel_announcement, short_channel_id: 2).get }
  #   #     let(:channels) { { channel1.short_channel_id => channel1, channel2.short_channel_id => channel2 } }
  #   #     it { expect(subject[1][:nodes].size).to eq 1 }
  #   #   end
  #   # end
  # end
end
