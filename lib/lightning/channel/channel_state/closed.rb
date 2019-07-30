# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Closed < ChannelState
        def next(message, data)
          case message
          when :shutdown
            if data.is_a? HasCommitments
              context.channel_db.remove(data.channel_id)
              context.broadcast << ChannelClosed.build(channel, channel_id: data.channel_id, short_channel_id: data.short_channel_id)
            end
            stop
          end
          [self, data]
        end

        def stop
          channel << :terminate!
        end
      end
    end
  end
end
