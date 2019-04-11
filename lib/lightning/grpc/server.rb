# frozen_string_literal: true

require 'lightning/channel/events'
require 'lightning/grpc/service_pb'
require 'lightning/grpc/service_services_pb'

module Lightning
  module Grpc
    class Server < Lightning::Grpc::LightningService::Service
      include Concurrent::Concern::Logging

      def self.run(publisher)
        addr = "0.0.0.0:8080"
        s = GRPC::RpcServer.new
        s.add_http2_port(addr, :this_port_is_insecure)
        s.handle(new(publisher))
        s.run_till_terminated
      end

      attr_reader :publisher

      def initialize(publisher)
        @publisher = publisher
      end

      def events(requests)
        log(Logger::INFO, 'Lightning::Grpc::Server#events', "#{requests.inspect}")
        events = []

        receiver = EventsReceiver.spawn(:receiver, events, publisher)
        requests.each do |request|
          receiver << request
        end

        EventsResponseEnum.new(events).each
      rescue => e
        log(Logger::ERROR, 'events', "#{e.message}")
        log(Logger::ERROR, 'events', "#{e.backtrace}")
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
