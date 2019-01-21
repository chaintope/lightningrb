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
        match message, (on ~Lightning::Payment::Messages::SendPayment do |msg|
          cycle = Lightning::Payment::PaymentLifecycle.spawn(:payment, node_id, context)
          cycle << msg
          payments[msg[:payment_hash]] = msg
        end), (on ~Lightning::Payment::Events::PaymentSucceeded do |event|
          payments.delete(event[:payment_hash])
        end), (on :payments do
          payments
        end)
      end
    end
  end
end
