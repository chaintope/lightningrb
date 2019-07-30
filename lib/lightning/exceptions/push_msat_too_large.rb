# frozen_string_literal: true

module Lightning
  module Exceptions
    class PushMsatTooLarge < StandardError
      attr_accessor :temporary_channel_id, :push_msat, :funding_satoshis
      def initialize(temporary_channel_id, push_msat, funding_satoshis)
        @temporary_channel_id = temporary_channel_id
        @push_msat = push_msat
        @funding_satoshis = funding_satoshis
      end
    end
  end
end
