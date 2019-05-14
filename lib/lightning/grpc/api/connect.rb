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

          receiver = ConnectReceiver.spawn(:receiver, events, context, publisher)
          receiver << request

          ConnectResponseEnum.new(events).each
        end

        class ConnectReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events, :context, :publisher

          def initialize(events, context, publisher)
            @events = events
            @context = context
            @publisher = publisher
          end

          def on_message(message)
            case message
            when Lightning::Grpc::ConnectRequest
              publisher << [:subscribe, Lightning::Io::Events::PeerConnected]
              publisher << [:subscribe, Lightning::Io::Events::PeerDisconnected]
              context.switchboard << Lightning::IO::PeerEvents::Connect[message.remote_node_id, message.host, message.port]
            else
              events << message
            end
          rescue NameError => e
            log(Logger::ERROR, 'connect', "#{e.message}")
            log(Logger::ERROR, 'connect', "#{e.backtrace}")
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
