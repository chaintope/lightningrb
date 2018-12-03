# frozen_string_literal: true

module Lightning
  module Exceptions
    class InsufficientFundsInWallet < StandardError
      def initialize(sum, required)
        @sum = sum
        @required = required
      end
    end
  end
end
