# frozen_string_literal: true

module Lightning
  module Channel
    module Helpers
      def self.final_script_pubkey(context)
        address = context.spv.generate_new_address(context.node_params.node_id)
        Bitcoin::Script.parse_from_addr(address).to_payload.bth
      end
    end
  end
end
