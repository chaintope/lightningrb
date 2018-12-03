# frozen_string_literal: true

module Lightning
  module Channel
    class Forwarder < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages

      def on_message(message)
        log(Logger::DEBUG, "Forwarder:#{self} message: #{message}, destination: #{@destination}")
        match message, (on ~LightningMessage do |m|
          @destination << m if @destination
        end), (on ~any do |actor|
          log(Logger::DEBUG, "set destination: #{actor}")
          @destination = actor
        end)
      end
    end
  end
end
