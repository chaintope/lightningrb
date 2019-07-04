# frozen_string_literal: true

module Lightning
  module Grpc
    module Api
      class Invoice
        attr_reader :context, :publisher

        def initialize(context, publisher)
          @context = context
          @publisher = publisher
        end

        def execute(request)
          payment = Lightning::Payment::Messages::ReceivePayment[request.amount_msat, request.description, '']
          message = context.payment_handler.ask!(payment)
          Lightning::Grpc::InvoiceResponse.new(message.to_h.merge(payload: message.to_bech32))
        end
      end
    end
  end
end
