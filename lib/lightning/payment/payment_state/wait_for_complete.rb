# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentState
      class WaitForComplete < PaymentState
        def next(message, data)
          match message, (on ~UpdateFulfillHtlc do |fulfill|
            # TODO: public PaymentSent event
            stop
          end), (on ~UpdateFailHtlc do |fail|
            error_packet = Sphinx.parse_error(fail[:reason].bth, data[:shared_secrets].htb)
            stop
          end)
        end

        def stop
          ask!(:terminate!) unless ask!(:terminated?)
        end
      end
    end
  end
end
