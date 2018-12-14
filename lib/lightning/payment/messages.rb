# frozen_string_literal: true

module Lightning
  module Payment
    module Messages
      SendPayment = Algebrick.type do
        fields  amount_msat: Numeric,
                payment_hash: String,
                target_node_id: String,
                routes: Array,
                final_cltv_expiry: Numeric
      end

      ReceivePayment = Algebrick.type do
        fields  amount_msat: Numeric,
                description: String
      end

      DataWaitForRequest = Algebrick.atom

      DataWaitForRoute = Algebrick.type do
        fields! sender: Concurrent::Actor::Reference,
                request: SendPayment,
                failures: Array
      end

      DataWaitForComplete = Algebrick.type do
        fields! sender: Concurrent::Actor::Reference,
                request: SendPayment,
                command: Lightning::Channel::Messages::CommandAddHtlc,
                failures: Array,
                shared_secrets: Array,
                ignore_nodes: Array,
                ignore_channels: Array,
                hops: Array
      end
    end
  end
end