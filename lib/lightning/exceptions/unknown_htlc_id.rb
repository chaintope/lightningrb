# frozen_string_literal: true

module Lightning
  module Exceptions
    class UnknownHtlcId < StandardError
      attr_accessor :commitments, :id
      def initialize(commitments, id)
        @commitments = commitments
        @id = id
      end
    end
  end
end
