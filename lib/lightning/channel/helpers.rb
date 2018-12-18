# frozen_string_literal: true

module Lightning
  module Channel
    module Helpers
      include Algebrick::Matching

      def get_channel_id(data)
        match data,
              (on DataWaitForOpenChannel do
                data.init_fundee.temporary_channel_id
              end), (on DataWaitForAcceptChannel do
                data.init_funder.temporary_channel_id
              end), (on DataWaitForFundingInternal do
                data.temporary_channel_id
              end), (on DataWaitForFundingCreated do
                data.temporary_channel_id
              end), (on DataWaitForFundingSigned do
                data.channel_id
              end), (on HasCommitments do
                data.channel_id
              end)
      end

      def self.final_script_pubkey(context)
        address = context.spv.generate_new_address(context.node_params.node_id)
        Bitcoin::Script.parse_from_addr(address).to_payload.bth
      end
    end
  end
end
