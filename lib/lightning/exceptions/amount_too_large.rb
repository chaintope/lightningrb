# frozen_string_literal: true

module Lightning
  module Exceptions
    class AmountTooLarge < StandardError
      attr_accessor :temporary_channel_id, :value, :limit
      def initialize(temporary_channel_id, value, limit)
        @temporary_channel_id = temporary_channel_id
        @value = value
        @limit = limit
      end
    end
  end
end
