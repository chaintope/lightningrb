# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidTransportVersion < StandardError
      def initialize(version, supported)
        @version = version
        @supported = supported
      end
    end
  end
end
