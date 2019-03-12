module Concurrent
  module Actor
    class Reference
      def perform_later(message, delayed: 5)
        task = Concurrent::TimerTask.new(execution_interval: delayed) do
          self << message
          task.shutdown
        end
        task.execute
      end
    end
  end
end
