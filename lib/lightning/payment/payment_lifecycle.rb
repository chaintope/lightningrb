# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentLifecycle < Concurrent::Actor::Context
      def initialize(node_id, context)
        @node_id = node_id
        @status = PaymentState::WaitForRequest.new(@node_id, context, self)
        @data = Algebrick::None
      end

      def on_message(message)
        log(Logger::DEBUG, "status=#{@status}, data=#{@data}")
        @status, @data = @status.next(message, @data)
      end
    end
  end
end
