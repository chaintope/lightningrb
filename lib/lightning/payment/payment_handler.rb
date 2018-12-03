# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentHandler < Concurrent::Actor::Context
      def initialize(context)
        @context = context
      end

      def on_message(message)
      end
    end
  end
end
