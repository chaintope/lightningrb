# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidKeyFormat < StandardError
      attr_accessor :temporary_channel_id, :public_key
      def initialize(temporary_channel_id, public_key)
        @temporary_channel_id = temporary_channel_id
        @public_key = public_key
      end
    end
  end
end
