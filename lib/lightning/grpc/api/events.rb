# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Events
        attr_reader :publisher

        def initialize(publisher)
          @publisher = publisher
        end

        def execute(requests)
          events = []

          receiver = EventsReceiver.spawn(:receiver, events, publisher)
          requests.each do |request|
            receiver << request
          end

          EventsResponseEnum.new(events).each
        end

        class EventsReceiver < Concurrent::Actor::Context
          include Concurrent::Concern::Logging

          attr_reader :events, :publisher

          def initialize(events, publisher)
            @events = events
            @publisher = publisher
          end

          def on_message(message)
            case message
            when Lightning::Grpc::EventsRequest
              clazz = Object.const_get(message.event_type, false)
              case message.operation
              when :SUBSCRIBE
                publisher << [:subscribe, clazz]
              when :UNSUBSCRIBE
                publisher << [:unsubscribe, clazz]
              else
                log(Logger::ERROR, 'events', "unsupported operation #{message.operation}")
              end
            else
              events << message
            end
          rescue NameError => e
            log(Logger::ERROR, 'events', "unsupported event_type #{message.event_type}")
            log(Logger::ERROR, 'events', "#{e.message}")
            log(Logger::ERROR, 'events', "#{e.backtrace}")
          end
        end

        class EventsResponseEnum
          attr_reader :events

          def initialize(events)
            @events = events
          end

          def each
            return enum_for(:each) unless block_given?
            loop do
              event = events.shift
              if event
                response = Lightning::Grpc::EventsResponse.new
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
