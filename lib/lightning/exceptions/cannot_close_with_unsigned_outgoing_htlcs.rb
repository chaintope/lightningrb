# frozen_string_literal: true

module Lightning
  module Exceptions
    class CannotCloseWithUnsignedOutgoingHtlcs < StandardError
      attr_accessor :commitments
      def initialize(commitments)
        @commitments = commitments
      end
    end
  end
end
