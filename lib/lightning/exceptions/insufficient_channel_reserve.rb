# frozen_string_literal: true

module Lightning
  module Exceptions
    class InsufficientChannelReserve < StandardError
      attr_accessor :channel_reserve_satoshis
      def initialize(channel_reserve_satoshis)
        @channel_reserve_satoshis = channel_reserve_satoshis
      end
    end
  end
end
