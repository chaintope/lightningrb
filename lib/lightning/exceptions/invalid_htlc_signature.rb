# frozen_string_literal: true

module Lightning
  module Exceptions
    class InvalidHtlcSignature < StandardError
      attr_accessor :local_sig, :remote_sig
      def initialize(local_sig, remote_sig)
        @local_sig = local_sig
        @remote_sig = remote_sig
      end
    end
  end
end
