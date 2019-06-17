# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Close
        attr_reader :context, :publisher

        def initialize(context, publisher)
          @context = context
          @publisher = publisher
        end

        def execute(request)
          events = []

          CloseReceiver.spawn(:receiver, events, context, publisher, request)
          CloseResponseEnum.new(events).each
        end

        class CloseReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events

          def initialize(events, context, publisher, request)
            @events = events
            @context = context
            @request = request
            @publisher = publisher
            publisher << [:subscribe, Lightning::Channel::Events::ChannelClosed]
            command = Lightning::Channel::Messages::CommandClose[request.script_pubkey || '']
            context.register << Lightning::Channel::Register::Forward[request.channel_id, command]
          end

          def on_message(message)
            case message
            when Lightning::Channel::Events::ChannelClosed
              if message.channel_id == @request.channel_id
                events << message
                @publisher.ask!(:unsubscribe)
                reference << :terminate!
              end
            end
          end
        end

        class CloseResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::CloseResponse.new
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
