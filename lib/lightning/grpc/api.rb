# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      autoload :Connect, 'lightning/grpc/api/connect'
      autoload :Events, 'lightning/grpc/api/events'
    end
  end
end
