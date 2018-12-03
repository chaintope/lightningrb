# frozen_string_literal: true

module Lightning
  module Exceptions
    class TemporaryChannelIdNotMatch < StandardError
      attr_accessor :temporary_channel_id
      def initialize(temporary_channel_id)
        @temporary_channel_id = temporary_channel_id
      end
    end
  end
end
