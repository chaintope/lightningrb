# frozen_string_literal: true

module Lightning
  module Exceptions
    class InsufficientChannelReserve < StandardError
      attr_accessor :temporary_channel_id, :channel_reserve_satoshis
      def initialize(temporary_channel_id, channel_reserve_satoshis)
        @temporary_channel_id = temporary_channel_id
        @channel_reserve_satoshis = channel_reserve_satoshis
      end
    end
  end
end
