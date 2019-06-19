# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Closing < ChannelState
        def next(message, data)
          case message
          when WatchEventConfirmed
            return [self, data] unless message[:event_type] == 'confirmed'
            goto(Closed.new(channel, context), data: data)
          when ClosingSigned
            # closing transaction has been already sent.
            return [self, data]
          else
            return [self, data]
          end
        end
      end
    end
  end
end
