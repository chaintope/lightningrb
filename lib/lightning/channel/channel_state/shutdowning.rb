# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Shutdowning < ChannelState
        def next(message, data)
          [self, data]
        end
      end
    end
  end
end
