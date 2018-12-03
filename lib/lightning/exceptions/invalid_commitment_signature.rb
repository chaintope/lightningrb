# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidCommitmentSignature < StandardError
      attr_accessor :channel_id, :tx
      def initialize(channel_id, tx)
        @channel_id = channel_id
        @tx = tx
      end
    end
  end
end
