# frozen_string_literal: true

module Lightning
  module Exceptions
    class AmountTooLarge < StandardError
      attr_accessor :value, :limit
      def initialize(value, limit)
        @value = value
        @limit = limit
      end
    end
  end
end
