# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Offline < ChannelState
        def next(message, data)
          match message, (on ~InputReconnected do |msg|
            context.forwarder << msg[:remote]
            reestablish = ChannelReestablish[
              data[:commitments][:channel_id],
              data[:commitments][:local_commit][:index] + 1,
              data[:commitments][:remote_commit][:index],
              '',
              ''
            ]
            goto(Syncing.new(channel, context), data: data, sending: reestablish)
          end)
        end
      end
    end
  end
end
