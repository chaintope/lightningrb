# frozen_string_literal: true

module Lightning
  module Exceptions
    class CannotAffordFees < StandardError
      attr_accessor :reduced, :channel_reserve_satoshis, :fees
      def initialize(reduced, channel_reserve_satoshis, fees)
        @reduced = reduced
        @channel_reserve_satoshis = channel_reserve_satoshis
        @fees = fees
      end
    end
  end
end
