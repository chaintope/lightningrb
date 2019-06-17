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
        s = GRPC::RpcServer.new(pool_size: 300)
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
        log(Logger::INFO, 'events', "#{requests.inspect}")
        Lightning::Grpc::Api::Events.new(publisher).execute(requests)
      rescue => e
        log(Logger::ERROR, 'events', "#{e.message}")
        log(Logger::ERROR, 'events', "#{e.backtrace}")
      end

      # Connect to remote node (if not connected)
      def connect(request, _call)
        log(Logger::INFO, 'connect', "#{request.inspect}")
        Lightning::Grpc::Api::Connect.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'connect', "#{e.message}")
        log(Logger::ERROR, 'connect', "#{e.backtrace}")
      end

      # Open channel between connected remote node
      def open(request, _call)
        log(Logger::INFO, 'open', "#{request.inspect}")
        Lightning::Grpc::Api::Open.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'open', "#{e.message}")
        log(Logger::ERROR, 'open', "#{e.backtrace}")
      end

      def invoice(request, _call)
        log(Logger::INFO, 'invoice', "#{request.inspect}")
        Lightning::Grpc::Api::Invoice.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'invoice', "#{e.message}")
        log(Logger::ERROR, 'invoice', "#{e.backtrace}")
      end

      def payment(request, _call)
        log(Logger::INFO, 'payment', "#{request.inspect}")
        Lightning::Grpc::Api::Payment.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'payment', "#{e.message}")
        log(Logger::ERROR, 'payment', "#{e.backtrace}")
      end

      # Find routing to target node
      def route(request, _call)
        log(Logger::INFO, 'route', "#{request.inspect}")
        Lightning::Grpc::Api::Route.new(context).execute(request)
      rescue => e
        log(Logger::ERROR, 'route', "#{e.message}")
        log(Logger::ERROR, 'route', "#{e.backtrace}")
      end

      def get_channel(request, _call)
        log(Logger::INFO, 'get_channel', "#{request.inspect}")
        Lightning::Grpc::Api::GetChannel.new(context).execute(request)
      rescue => e
        log(Logger::ERROR, 'get_channel', "#{e.message}")
        log(Logger::ERROR, 'get_channel', "#{e.backtrace}")
      end

      def list_channels(request, _call)
        log(Logger::INFO, 'list_channels', "#{request.inspect}")
        Lightning::Grpc::Api::ListChannels.new(context).execute(request)
      rescue => e
        log(Logger::ERROR, 'list_channels', "#{e.message}")
        log(Logger::ERROR, 'list_channels', "#{e.backtrace}")
      end

      def close(request, _call)
        log(Logger::INFO, 'close', "#{request.inspect}")
        Lightning::Grpc::Api::Close.new(context, publisher).execute(request)
      rescue => e
        log(Logger::ERROR, 'close', "#{e.message}")
        log(Logger::ERROR, 'close', "#{e.backtrace}")
      end
    end
  end
end
