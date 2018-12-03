module Lightning
  module Payment
    module Events
      include Algebrick
      module PaymentEvent
      end

      PaymentSent = Algebrick.type do
        fields  amount: Numeric,
                fees_paid: Numeric,
                payment_hash: String
      end

      PaymentRelayed = Algebrick.type do
        fields  amount_in: Numeric,
                amount_out: Numeric,
                payment_hash: String
      end

      PaymentReceived = Algebrick.type do
        fields  amount: Numeric,
                payment_hash: String
      end

      PaymentSucceeded = Algebrick.type do
        fields amount_msat: Numeric,
        payment_hash: String,
        payment_preimage: String,
        route: Array
      end

      PaymentFailed = Algebrick.type do
        fields payment_hash: String,
        failure: Array
      end
    end
  end
end
