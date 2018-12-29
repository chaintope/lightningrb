# frozen_string_literal: true

module Lightning
  module Router
    class RouterState
      include Concurrent::Concern::Logging
      include Algebrick
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages
      include Lightning::Channel::Events
      include Lightning::Blockchain::Messages
      include Lightning::Router::Messages

      autoload :Normal, 'lightning/router/router_state/normal'
      autoload :WaitingForValidation, 'lightning/router/router_state/waiting_for_validation'

      attr_accessor :router, :context

      def initialize(router, context)
        @router = router
        @context = context
      end

      def goto(new_status, data: nil)
        @data = data
        [new_status, @data]
      end

      def next(message, data)
        log(Logger::DEBUG, 'router_state', "data:#{data}")
        match message, (on ~LocalChannelUpdate do |event|
          channel = data[:channels][event[:short_channel_id]]
          unless channel
            router << event[:channel_announcement].value unless event[:channel_announcement].is_a? None
          end
          router << event[:channel_update]
          [self, data]
        end), (on ~LocalChannelDown do |event|
          channel = data[:channels][event[:short_channel_id]]
          desc = Announcements.to_channel_desc(channel)
          [self, data]
          # [self, data.copy(updates: data[:updates].merge({ desc => msg }))]
        end), (on ~ChannelAnnouncement do |msg|
          if data[:channels].key?(msg[:short_channel_id])
            # ignore
            [self, data]
          elsif !msg.valid_signature?
            # TODO: router.parent << :error
            log(Logger::DEBUG, 'router_state', "signature invalid #{msg.to_payload.bth}")
            [self, data]
          else
            [self, data.copy(channels: data[:channels].merge(msg[:short_channel_id] => msg))]
          end
        end), (on ~NodeAnnouncement do |msg|
          if data[:nodes].key?(msg[:node_id]) && msg.older_than?(data[:nodes][msg[:node_id]])
            [self, data]
          elsif !msg.valid_signature?
            # TODO: router.parent << :error
            log(Logger::DEBUG, 'router_state', "signature invalid #{msg.to_payload.bth}")
            [self, data]
          elsif data[:nodes].key?(msg[:node_id])
            # TODO: NodeUpdate event
            context.node_db.update(msg)
            [self, data.copy(nodes: data[:nodes].merge(msg[:node_id] => msg))]
          elsif data[:channels].values.any? { |channel| related?(channel, msg[:node_id]) }
            # TODO: NodeDiscovered event
            context.node_db.create(msg)
            [self, data.copy(nodes: data[:nodes].merge(msg[:node_id] => msg))]
          else
            context.node_db.destroy_by(node_id: msg[:node_id])
            [self, data]
          end
        end), (on ~ChannelUpdate do |msg|
          if data[:channels].key?(msg[:short_channel_id])
            channel = data[:channels][msg[:short_channel_id]]
            desc = Announcements.to_channel_desc(channel)
            node_id =
              if (msg[:channel_flags] & (2**0)).zero?
                channel[:node_id_2]
              else
                channel[:node_id_1]
              end
            if data[:updates].key?(desc) && data[:updates][desc].timestamp >= msg.timestamp
              log(Logger::DEBUG, 'router_state', "ignore old update #{msg.to_payload.bth}")
              # ignore
              [self, data]
            elsif !msg.valid_signature?(node_id)
              # TODO: router.parent << :error
              log(Logger::DEBUG, 'router_state', "signature invalid #{msg.to_payload.bth}")
              [self, data]
            elsif data[:updates].key?(desc)
              # TODO: ChannelUpdateReceived
              # context.channel_db.update_channel_update(msg)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Updated #{msg}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => msg))]
            else
              # TODO: ChannelUpdateReceived
              # context.channel_db.add_channel_update(msg)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Registered #{msg}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => msg))]
            end
          else
            # TODO: wait for channel_announcement
            log(Logger::DEBUG, 'router_state', "wait for channel_announcement #{msg.to_payload.bth}")
            [self, data]
          end
        end), (on RouteRequest.(~any, ~any, ~any) do |source, target, assisted_routes|
          ignore_nodes = []
          ignore_channels = []
          hops = RouteFinder.find(source, target, data[:updates], assisted_routes)
          if router.envelope.sender.is_a? Concurrent::Actor::Reference
            router.envelope.sender << RouteResponse[hops, ignore_nodes, ignore_channels]
          end
          [self, data]
        rescue Lightning::Exceptions::RouteNotFound => e
          log(Logger::DEBUG, 'router_state', 'Route to the final node is not found. Retry after a while')
          log(Logger::DEBUG, 'router_state', e.message)
          [self, data]
        end)
      end

      def related?(channel, node_id)
        node_id == channel.node_id_1 || node_id == channel.node_id_2
      end
    end
  end
end
