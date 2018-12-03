# frozen_string_literal: true

module Lightning
  module Exceptions
    class HtlcSigCountMismatch < StandardError
      attr_accessor :num_of_signatures, :local_htlcs_size
      def initialize(num_of_signatures, local_htlcs_size)
        @num_of_signatures = num_of_signatures
        @local_htlcs_size = local_htlcs_size
      end
    end
  end
end
