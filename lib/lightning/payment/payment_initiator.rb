# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentInitiator < Concurrent::Actor::Context
      include Algebrick::Matching

      attr_accessor :node_id, :context, :payments

      def initialize(node_id, context)
        @node_id = node_id
        @context = context
        context.broadcast << [:subscribe, Lightning::Payment::Events::PaymentSucceeded]
        @payments = {}
      end

      def on_message(message)
        case message
        when Lightning::Payment::Messages::SendPayment
          cycle = Lightning::Payment::PaymentLifecycle.spawn(:payment, node_id, context)
          cycle << message
          payments[message[:payment_hash]] = message
        when Lightning::Payment::Events::PaymentSucceeded
          payments.delete(message.payment_hash)
        when :payments
          payments
        end
      end
    end
  end
end
