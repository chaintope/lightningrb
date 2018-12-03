# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Closed < ChannelState
        def next(message, data)
          match message, (on :shutdown do
            if data.is_a? HasCommitments
              context.channel_db.remove(data.channel_id)
            end
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
