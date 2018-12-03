# frozen_string_literal: true

module Lightning
  module Exceptions
    class CannotSignWithoutChanges < StandardError
      attr_accessor :commitments
      def initialize(commitments)
        @commitments = commitments
      end
    end
  end
end
