# frozen_string_literal: true

module Lightning
  module Exceptions
    class InsufficientFunds < StandardError
      def initialize(commitments, add, reduced, fee)
        @commitments = commitments
        @add = add
        @reduced = reduced
        @fee = fee
      end
    end
  end
end
