# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Closing < ChannelState
        def next(message, data)
          match message, (on ~WatchEventConfirmed do |event|
            return [self, data] unless event[:event_type] == 'confirmed'
            goto(Closed.new(channel, context), data: data)
          end), (on ~ClosingSigned do |msg|
            # closing transaction has been already sent.
            return [self, data]
          end)
        end
      end
    end
  end
end
