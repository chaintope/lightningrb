# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Open
        attr_reader :context, :publisher

        def initialize(context, publisher)
          @context = context
          @publisher = publisher
        end

        def execute(request)
          events = []

          OpenReceiver.spawn(:receiver, events, context, publisher, request)
          OpenResponseEnum.new(events).each
        end

        class OpenReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events, :context

          def initialize(events, context, publisher, request)
            @events = events
            @context = context
            @request = request
            publisher << [:subscribe, Lightning::Channel::Events::ChannelCreated]
            publisher << [:subscribe, Lightning::Channel::Events::ChannelRestored]
            publisher << [:subscribe, Lightning::Channel::Events::ChannelIdAssigned]
            publisher << [:subscribe, Lightning::Channel::Events::ShortChannelIdAssigned]
            publisher << [:subscribe, Lightning::Channel::Events::LocalChannelUpdate]
            publisher << [:subscribe, Lightning::Router::Events::ChannelRegistered]
            publisher << [:subscribe, Lightning::Router::Events::ChannelUpdated]
            context.switchboard << Lightning::IO::PeerEvents::OpenChannel[
              request.remote_node_id, request.funding_satoshis, request.push_msat, request.channel_flags, ''
            ]
          end

          def on_message(message)
            case message
            when Lightning::Channel::Events::ChannelCreated
              if message.remote_node_id == @request.remote_node_id
                @temporary_channel_id = message.temporary_channel_id
                events << message
              end
            when Lightning::Channel::Events::ChannelIdAssigned
              if message.temporary_channel_id == @temporary_channel_id
                @channel_id = message.channel_id
                events << message
              end
            when Lightning::Channel::Events::ShortChannelIdAssigned
              if message.channel_id == @channel_id
                @short_channel_id = message.short_channel_id
                events << message
              end
            when Lightning::Router::Events::ChannelRegistered
              if message.short_channel_id == @short_channel_id
                events << message
              end
            when Lightning::Router::Events::ChannelUpdated
              if message.short_channel_id == @short_channel_id
                events << message
              end
            end
          end
        end

        class OpenResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::OpenResponse.new
                field = event.class.name.split('::').last.snake
                response[field] = event
                yield response
              else
                sleep(1)
              end
            end
          end
        end
      end
    end
  end
end
