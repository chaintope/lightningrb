# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Offline < ChannelState
        def next(message, data)
          case message
          when InputReconnected
            context.forwarder << message[:remote]
            reestablish = ChannelReestablish.new(
              channel_id: data[:commitments][:channel_id],
              next_local_commitment_number: data[:commitments][:local_commit][:index] + 1,
              next_remote_revocation_number: data[:commitments][:remote_commit][:index],
              your_last_per_commitment_secret: '00' * 32,
              my_current_per_commitment_point: '00' * 32
            )
            goto(Syncing.new(channel, context), data: data, sending: reestablish)
          end
        end
      end
    end
  end
end
