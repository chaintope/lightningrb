# frozen_string_literal: true

module Lightning
  module Exceptions
    class RouteNotFound < StandardError
      def initialize(source, target)
        @source = source
        @target = target
      end
    end
  end
end
