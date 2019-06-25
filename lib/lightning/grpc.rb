# frozen_string_literal: true

require 'lightning/grpc/lightning_service'

module Lightning
  module Grpc
    autoload :Api, 'lightning/grpc/api'
    autoload :Server, 'lightning/grpc/server'
  end
end
