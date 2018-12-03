# frozen_string_literal: true

module Lightning
  module Router
    class Router < Concurrent::Actor::Context
      include Lightning::Wire::LightningMessages
      include Lightning::Channel::Events

      attr_accessor :state

      def initialize(context)
        @context = context
        nodes = Hash[context.node_db.all.map { |node| [node.node_id, node] }]
        @state = Lightning::Router::RouterState::Normal.new(self, context)

        @data = Lightning::Router::Messages::Data[nodes, {}, {}]

        context.broadcast << [:subscribe, LocalChannelUpdate]
        context.broadcast << [:subscribe, LocalChannelDown]
      end

      def on_message(message)
        case message
        when :nodes
          return @data[:nodes].values
        end
        @state, @data = @state.next(message, @data)
      end
    end
  end
end
