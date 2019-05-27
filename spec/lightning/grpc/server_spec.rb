# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Grpc::Server do
  describe '#events' do
    subject do
      response = described_class.new(context, publisher).events(requests)
      sleep(1) # Idle for subscribing events
      publisher.ask(:await).wait
      response
    end

    let(:requests) { [Lightning::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "Lightning::Channel::Events::ChannelCreated")] }
    let(:publisher) { Lightning::IO::Broadcast.spawn(:broadcast) }
    let(:channel) { spawn_dummy_actor }
    let(:context) { build(:context) }

    it 'subscribe' do
      expect(publisher).to receive(:<<).with([:subscribe, Lightning::Channel::Events::ChannelCreated])
      subject
    end

    it 'publish' do
      responses = subject
      channel_created = Lightning::Channel::Events::ChannelCreated.build(
        channel,
        remote_node_id: "00" * 32, is_funder: 1, temporary_channel_id: "11" * 32
      )
      publisher << channel_created
      publisher.ask(:await).wait
      response_event = responses.each do |response|
        break response.channel_created
      end
      expect(response_event).to eq channel_created
    end
  end
end
