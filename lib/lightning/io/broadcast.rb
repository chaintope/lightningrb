# frozen_string_literal: true

module Lightning
  module IO
    class Broadcast < Concurrent::Actor::RestartingContext
      include Algebrick

      def initialize
        @receivers = {}
      end

      def on_message(message)
        match message, (on Array.(:subscribe, ~any) do |type|
          if envelope.sender.is_a? Concurrent::Actor::Reference
            @receivers[type.name] ||= []
            @receivers[type.name] << envelope.sender
          end
        end), (on :unsubscribe do
          @receivers.each { |receiver| receiver.delete(envelope.sender) }
        end), (on Array.(:subscribe?, ~any) do |type|
          @receivers[type.name]&.include?(envelope.sender)
        end), (on any do
          key = if message&.respond_to?(:type) && message.type.respond_to?(:name)
            message.type.name
          else
            message.class.name
          end
          @receivers[key]&.each { |r| r << message }
        end)
      end
    end
  end
end
