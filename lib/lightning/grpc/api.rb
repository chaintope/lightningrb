# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      autoload :Connect, 'lightning/grpc/api/connect'
      autoload :Events, 'lightning/grpc/api/events'
      autoload :Open, 'lightning/grpc/api/open'
      autoload :Invoice, 'lightning/grpc/api/invoice'
    end
  end
end
