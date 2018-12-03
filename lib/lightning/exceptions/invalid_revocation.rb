# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidRevocation < StandardError
      attr_accessor :revocation
      def initialize(revocation)
        @revocation = revocation
      end
    end
  end
end
