# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentState
      class WaitForComplete < PaymentState
        def next(message, data)
          case message
          when UpdateFulfillHtlc
            stop
          when UpdateFailHtlc
            error_packet = Sphinx.parse_error(message[:reason].bth, data[:shared_secrets].htb)
            stop
          end
        end

        def stop
          channel.ask!(:terminate!) unless channel.ask!(:terminated?)
        end
      end
    end
  end
end
