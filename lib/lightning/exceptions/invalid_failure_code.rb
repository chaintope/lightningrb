# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidFailureCode < StandardError
      attr_accessor :failure_code
      def initialize(failure_code)
        @failure_code = failure_code
      end
    end
  end
end
