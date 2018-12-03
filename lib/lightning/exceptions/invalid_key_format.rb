# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidKeyFormat < StandardError
      attr_accessor :public_key
      def initialize(public_key)
        @public_key = public_key
      end
    end
  end
end
