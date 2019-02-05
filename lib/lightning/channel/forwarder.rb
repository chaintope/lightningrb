# frozen_string_literal: true

module Lightning
  module Channel
    class Forwarder < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages

      def on_message(message)
        log(Logger::DEBUG, "Forwarder:#{self} message: #{message}, destination: #{@destination}")
        case message
        when Lightning::Wire::LightningMessages
          @destination << message if @destination
        else
          log(Logger::DEBUG, "set destination: #{message}")
          @destination = message
        end
      end
    end
  end
end
