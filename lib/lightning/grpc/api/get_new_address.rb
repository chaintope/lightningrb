# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class GetNewAddress
        attr_reader :context

        def initialize(context)
          @context = context
        end

        def execute(request)
          address = context.spv.generate_new_address(context.node_params.node_id)
          script_pubkey = Bitcoin::Script.parse_from_addr(address).to_payload.bth
          Lightning::Grpc::GetNewAddressResponse.new(address: address, script_pubkey: script_pubkey)
        end
      end
    end
  end
end
