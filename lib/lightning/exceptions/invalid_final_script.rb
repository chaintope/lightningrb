# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidFinalScript < StandardError
      def initialize(commitments)
        @commitments = commitments
      end
    end
  end
end
