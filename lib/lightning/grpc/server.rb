# frozen_string_literal: true

module Lightning
  module Grpc
    class Server
      include Concurrent::Concern::Logging

      def initialize(context)
        addr = "0.0.0.0:8080"
        @connection = GRPC::RpcServer.new(pool_size: 300)
        @connection.add_http2_port(addr, :this_port_is_insecure)
        add_service(Lightning::Grpc::LightningService::ServiceImpl.new(context, context.broadcast))
      end

      def run
        @connection.run_till_terminated
      end

      def add_service(service)
        @connection.handle(service)
      end
    end
  end
end
