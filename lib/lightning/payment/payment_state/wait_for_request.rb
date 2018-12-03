# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentState
      class WaitForRequest < PaymentState
        def next(message, data)
          match message, (on ~Lightning::Payment::Messages::SendPayment do |msg|
            # TODO: Assisted Routes
            context.router << Lightning::Router::Messages::RouteRequest[node_id, msg[:target_node_id], msg[:routes]]
            goto(
              WaitForRoute.new(node_id, context, payment),
              data: Lightning::Payment::Messages::DataWaitForRoute[payment.reference, msg, []]
            )
          end)
        end
      end
    end
  end
end
