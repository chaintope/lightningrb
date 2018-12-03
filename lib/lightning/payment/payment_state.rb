# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentState
      include Concurrent::Concern::Logging
      include Lightning::Utils::Algebrick
      include Algebrick::Matching
      include Lightning::Exceptions
      include Lightning::Channel::Messages

      autoload :WaitForComplete, 'lightning/payment/payment_state/wait_for_complete'
      autoload :WaitForRequest, 'lightning/payment/payment_state/wait_for_request'
      autoload :WaitForRoute, 'lightning/payment/payment_state/wait_for_route'

      attr_accessor :node_id, :context, :payment

      def initialize(node_id, context, payment)
        @node_id = node_id
        @context = context
        @payment = payment
      end

      def goto(new_status, data: nil)
        @data = data
        [new_status, @data]
      end
    end
  end
end
