# frozen_string_literal: true

module Lightning
  module Exceptions
    class OutputNotFound < StandardError
      attr_accessor :tx, script_pubkey
      def initialize(tx, script_pubkey)
        @tx = tx
        @script_pubkey = script_pubkey
      end
    end
  end
end
