# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentState
      class WaitForRoute < PaymentState
        include RouteBuilder
        def next(message, data)
          case message
          when Lightning::Router::Messages::RouteResponse
            first_hop = message[:hops].first
            final_expiry = block_height + data[:request][:final_cltv_expiry]
            cmd, shared_secrets = build_command(data[:request], final_expiry, message[:hops])
            context.register << Lightning::Channel::Register::ForwardShortId[first_hop.last_update.short_channel_id, cmd]
            goto(
              WaitForComplete.new(node_id, context, payment),
              data: Lightning::Payment::Messages::DataWaitForComplete[
                payment.reference,
                data[:request],
                cmd,
                data[:failures],
                shared_secrets,
                message[:ignore_nodes],
                message[:ignore_channels],
                message[:hops]
              ]
            )
          when :route_not_found
          end
        end

        def block_height
          context.spv.block_height
        end
      end
    end
  end
end
