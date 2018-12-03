# frozen_string_literal: true

module Lightning
  module Exceptions
    class PushMsatTooLarge < StandardError
      attr_accessor :push_msat, :funding_satoshis
      def initialize(push_msat, funding_satoshis)
        @push_msat = push_msat
        @funding_satoshis = funding_satoshis
      end
    end
  end
end
