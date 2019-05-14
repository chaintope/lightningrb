# frozen_string_literal: true

# require 'lightning/channel/events'
# require 'lightning/grpc/service_pb'
# require 'lightning/grpc/service_services_pb'

module Lightning
  module Grpc
    class Server < Lightning::Grpc::LightningService::Service
      include Concurrent::Concern::Logging

      def self.run(context, publisher)
        addr = "0.0.0.0:8080"
        s = GRPC::RpcServer.new
        s.add_http2_port(addr, :this_port_is_insecure)
        s.handle(new(context, publisher))
        s.run_till_terminated
      end

      attr_reader :context, :publisher

      def initialize(context, publisher)
        @context = context
        @publisher = publisher
      end

      def events(requests)
        Lightning::Grpc::Api::Events.new(publisher).execute(requests)
      rescue => e
        log(Logger::ERROR, 'events', "#{e.message}")
        log(Logger::ERROR, 'events', "#{e.backtrace}")
      end

      def connect(request, _call)
        Lightning::Grpc::Api::Connect.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'connect', "#{e.message}")
        log(Logger::ERROR, 'connect', "#{e.backtrace}")
      end
    end
  end
end
