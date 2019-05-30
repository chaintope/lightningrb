# frozen_string_literal: true

module Lightning
  module Exceptions
    class HtlcValueTooHighInFlight < StandardError
      attr_accessor :max_htlc_value_in_flight_msat, :htlc_value_in_flight
      def initialize(max_htlc_value_in_flight_msat, htlc_value_in_flight)
        @max_htlc_value_in_flight_msat = max_htlc_value_in_flight_msat
        @htlc_value_in_flight = htlc_value_in_flight
      end

      def to_s
        "HtlcValueTooHighInFlight: max=#{max_htlc_value_in_flight_msat}, actual=#{htlc_value_in_flight}"
      end
    end
  end
end
