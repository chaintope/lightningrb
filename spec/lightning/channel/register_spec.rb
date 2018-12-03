# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::Register do
  describe 'on fire event' do
    subject do
      register << message
      register.ask(:await).wait
    end

    let(:context) { Lightning::Context.new(create_test_spv) }
    let(:register) { described_class.spawn(:register, context) }
    let(:channel) { spawn_dummy_actor }
    let(:peer) { spawn_dummy_actor }
    let(:node_id) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    let(:temporary_channel_id) { '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357' }
    let(:channel_id) { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    let(:short_channel_id) { 42 }

    describe 'ChannelCreated' do
      let(:message) { Lightning::Channel::Events::ChannelCreated[channel, peer, node_id, 1, temporary_channel_id] }

      it 'registers to channel with temporary_channel_id' do
        subject
        expect(register.ask!(:channels)[temporary_channel_id]).to eq channel
      end

      it 'registers to remotes with temporary_channel_id' do
        subject
        expect(register.ask!(:remotes)[temporary_channel_id]).to eq node_id
      end
    end

    describe 'ChannelIdAssigned' do
      let(:message) { Lightning::Channel::Events::ChannelIdAssigned[channel, node_id, temporary_channel_id, channel_id] }

      it 'replaces key in channels' do
        subject
        expect(register.ask!(:channels)[temporary_channel_id]).to be_nil
        expect(register.ask!(:channels)[channel_id]).to eq channel
      end

      it 'replaces key in remotes' do
        subject
        expect(register.ask!(:remotes)[temporary_channel_id]).to be_nil
        expect(register.ask!(:remotes)[channel_id]).to eq node_id
      end
    end

    describe 'ShortChannelIdAssigned' do
      let(:message) { Lightning::Channel::Events::ShortChannelIdAssigned[channel, channel_id, short_channel_id] }

      it 'registers to short_channel_ids' do
        subject
        expect(register.ask!(:short_channel_ids)[short_channel_id]).to eq channel_id
      end
    end

    describe 'Forward' do
      let(:lightning_message) { build(:update_fulfill_htlc).get }
      let(:message) { Lightning::Channel::Register::Forward[channel_id, lightning_message] }

      before do
        register << Lightning::Channel::Events::ChannelCreated[channel, peer, node_id, 1, temporary_channel_id]
        register << Lightning::Channel::Events::ChannelIdAssigned[channel, node_id, temporary_channel_id, channel_id]
      end

      it 'forward lightning_message to channel' do
        expect(channel).to receive(:<<).with(lightning_message)
        subject
      end
    end

    describe 'ForwardShortId' do
      let(:lightning_message) { build(:update_fulfill_htlc).get }
      let(:message) { Lightning::Channel::Register::ForwardShortId[short_channel_id, lightning_message] }

      before do
        register << Lightning::Channel::Events::ChannelCreated[channel, peer, node_id, 1, temporary_channel_id]
        register << Lightning::Channel::Events::ChannelIdAssigned[channel, node_id, temporary_channel_id, channel_id]
        register << Lightning::Channel::Events::ShortChannelIdAssigned[channel, channel_id, short_channel_id]
      end

      it 'forward lightning_message to channel' do
        expect(channel).to receive(:<<).with(lightning_message)
        subject
      end
    end
  end
end
