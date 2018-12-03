# frozen_string_literal: true

module Lightning
  module Exceptions
    class CannotExtractSharedSecret < StandardError
      attr_accessor :packet
      def initialize(packet)
        @packet = packet
      end
    end
  end
end
