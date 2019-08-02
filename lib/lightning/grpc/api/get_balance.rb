# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class GetBalance
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def execute(request)
          balance = context.spv.get_balance(context.node_params.node_id)
          Lightning::Grpc::GetBalanceResponse.new(balance: balance)
        end
      end
    end
  end
end
