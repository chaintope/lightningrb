# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidHtlcPreimage < StandardError
      attr_accessor :htlc, :payment_hash
      def initialize(htlc, payment_hash)
        @htlc = htlc
        @payment_hash = payment_hash
      end
    end
  end
end
