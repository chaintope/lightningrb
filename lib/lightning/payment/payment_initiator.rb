# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentInitiator < Concurrent::Actor::Context
      include Algebrick::Matching

      attr_accessor :node_id, :context

      def initialize(node_id, context)
        @node_id = node_id
        @context = context
      end

      def on_message(message)
        match message, (on ~Lightning::Payment::Messages::SendPayment do |msg|
          cycle = Lightning::Payment::PaymentLifecycle.spawn(:payment, node_id, context)
          cycle << msg
        end)
      end
    end
  end
end
