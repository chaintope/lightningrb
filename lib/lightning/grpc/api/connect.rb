# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Connect
        attr_reader :context, :publisher

        def initialize(context, publisher)
          @context = context
          @publisher = publisher
        end

        def execute(request)
          events = []

          ConnectReceiver.spawn(:receiver, events, context, publisher, request)

          ConnectResponseEnum.new(events).each
        end

        class ConnectReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events

          def initialize(events, context, publisher, request)
            @events = events
            @request = request
            publisher << [:subscribe, Lightning::Io::Events::PeerConnected]
            publisher << [:subscribe, Lightning::Io::Events::PeerAlreadyConnected]
            publisher << [:subscribe, Lightning::Io::Events::PeerDisconnected]

            context.switchboard << Lightning::IO::PeerEvents::Connect[request.remote_node_id, request.host, request.port]
          end

          def on_message(message)
            case message
            when Lightning::Io::Events::PeerConnected, Lightning::Io::Events::PeerAlreadyConnected
              if message.remote_node_id == @request.remote_node_id
                events << message
              end
            when Lightning::Io::Events::PeerDisconnected
              if message.remote_node_id == @request.remote_node_id
                events << message
              end
            end
          end
        end

        class ConnectResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::ConnectResponse.new
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
