# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      autoload :GetNewAddress, 'lightning/grpc/api/get_new_address'
      autoload :GetBalance, 'lightning/grpc/api/get_balance'
      autoload :Connect, 'lightning/grpc/api/connect'
      autoload :Events, 'lightning/grpc/api/events'
      autoload :Invoice, 'lightning/grpc/api/invoice'
      autoload :Open, 'lightning/grpc/api/open'
      autoload :Payment, 'lightning/grpc/api/payment'
      autoload :Route, 'lightning/grpc/api/route'
      autoload :GetChannel, 'lightning/grpc/api/get_channel'
      autoload :ListChannels, 'lightning/grpc/api/list_channels'
      autoload :Close,  'lightning/grpc/api/close'
    end
  end
end
