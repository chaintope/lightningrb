# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      autoload :Connect, 'lightning/grpc/api/connect'
      autoload :Events, 'lightning/grpc/api/events'
      autoload :Invoice, 'lightning/grpc/api/invoice'
      autoload :Open, 'lightning/grpc/api/open'
      autoload :Payment, 'lightning/grpc/api/payment'
      autoload :Route, 'lightning/grpc/api/route'
    end
  end
end
