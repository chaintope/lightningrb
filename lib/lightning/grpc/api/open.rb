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

          receiver = OpenReceiver.spawn(:receiver, events, context, publisher)
          receiver << request

          OpenResponseEnum.new(events).each
        end

        class OpenReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events, :context, :publisher

          def initialize(events, context, publisher)
            @events = events
            @context = context
            @publisher = publisher
          end

          def on_message(message)
            case message
            when Lightning::Grpc::OpenRequest
              publisher << [:subscribe, Lightning::Channel::Events::ChannelCreated]
              publisher << [:subscribe, Lightning::Channel::Events::ChannelRestored]
              publisher << [:subscribe, Lightning::Channel::Events::ChannelIdAssigned]
              publisher << [:subscribe, Lightning::Channel::Events::ShortChannelIdAssigned]
              publisher << [:subscribe, Lightning::Channel::Events::LocalChannelUpdate]
              publisher << [:subscribe, Lightning::Router::Events::ChannelRegistered]
              publisher << [:subscribe, Lightning::Router::Events::ChannelUpdated]
              context.switchboard << Lightning::IO::PeerEvents::OpenChannel[
                message.remote_node_id, message.funding_satoshis, message.push_msat, message.channel_flags, {}
              ]
            else
              events << message
            end
          rescue NameError => e
            log(Logger::ERROR, 'connect', "#{e.message}")
            log(Logger::ERROR, 'connect', "#{e.backtrace}")
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
