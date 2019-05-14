# frozen_string_literal: true

module Lightning
  module Grpc
    autoload :Api, 'lightning/grpc/api'
    autoload :Server, 'lightning/grpc/server'
    autoload :LightningService, 'lightning/grpc/service_services_pb'
  end
end
