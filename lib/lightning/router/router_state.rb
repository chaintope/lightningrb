# frozen_string_literal: true

module Lightning
  module Router
    class RouterState
      include Concurrent::Concern::Logging
      include Algebrick
      include Algebrick::Matching
      include Lightning::Wire::LightningMessages
      include Lightning::Channel::Events
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
        case message
        when Lightning::Router::Messages::Timeout
          log(Logger::DEBUG, 'router_state', "router state update.")
          context.switchboard << data if context.switchboard && data
          [self, data]
        when LocalChannelUpdate
          channel = data[:channels][message[:short_channel_id]]
          unless channel
            router << message[:channel_announcement].value unless message[:channel_announcement].is_a? None
          end
          router << message[:channel_update]
          [self, data]
        when LocalChannelDown
          channel = data[:channels][message[:short_channel_id]]
          desc = Announcements.to_channel_desc(channel)
          [self, data]
        when ChannelAnnouncement
          if data[:channels].key?(message.short_channel_id)
            # ignore
            log(Logger::WARN, 'router_state', "channel annoucement is ignored #{message.inspect}")
            [self, data]
          elsif !message.valid_signature?
            # TODO: router.parent << :error
            log(Logger::ERROR, 'router_state', "signature invalid #{message.inspect}")
            [self, data]
          else
            context.channel_db.insert_or_update_channel_announcement(message)
            [self, data.copy(channels: data[:channels].merge(message.short_channel_id => message))]
          end
        when NodeAnnouncement
          if data[:nodes].key?(message.node_id) && message.older_than?(data[:nodes][message.node_id])
            log(Logger::WARN, 'router_state', "node annoucement is ignored #{message.inspect}")
            [self, data]
          elsif !message.valid_signature?
            # TODO: router.parent << :error
            log(Logger::ERROR, 'router_state', "signature invalid #{message.inspect}")
            [self, data]
          elsif data[:nodes].key?(message.node_id)
            # TODO: NodeUpdate event
            context.node_db.update(message)
            [self, data.copy(nodes: data[:nodes].merge(message.node_id => message))]
          elsif data[:channels].values.any? { |channel| related?(channel, message.node_id) }
            # TODO: NodeDiscovered event
            context.node_db.insert(message)
            [self, data.copy(nodes: data[:nodes].merge(message.node_id => message))]
          else
            context.node_db.destroy_by(node_id: message.node_id)
            [self, data]
          end
        when ChannelUpdate
          if data[:channels].key?(message.short_channel_id)
            channel = data[:channels][message.short_channel_id]
            desc = Announcements.to_channel_desc(channel)
            node_id =
              if message[:channel_flags].to_i(16) & (2**0) == 0
                channel[:node_id_2]
              else
                channel[:node_id_1]
              end
            if data[:updates].key?(desc) && data[:updates][desc].timestamp >= message.timestamp
              log(Logger::DEBUG, 'router_state', "ignore old update #{message.to_payload.bth}")
              # ignore
              [self, data]
            elsif !message.valid_signature?(node_id)
              # TODO: router.parent << :error
              log(Logger::DEBUG, 'router_state', "signature invalid #{message.to_payload.bth}")
              [self, data]
            elsif data[:updates].key?(desc)
              # TODO: ChannelUpdateReceived
              context.channel_db.insert_or_update_channel_update(message)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Updated #{message.inspect}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => message))]
            else
              # TODO: ChannelUpdateReceived
              context.channel_db.insert_or_update_channel_update(message)
              log(Logger::INFO, :router_state, '================================================================================')
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, "Channel Registered #{message.inspect}")
              log(Logger::INFO, :router_state, '')
              log(Logger::INFO, :router_state, '================================================================================')
              [self, data.copy(updates: data[:updates].merge(desc => message))]
            end
          else
            # TODO: wait for channel_announcement
            log(Logger::DEBUG, 'router_state', "wait for channel_announcement #{message.to_payload.bth}")
            [self, data]
          end
        when RouteRequest
          begin
            ignore_nodes = []
            ignore_channels = []
            hops = RouteFinder.find(message[:source], message[:target], data[:updates], message[:assisted_routes])
            if router.envelope.sender.is_a? Concurrent::Actor::Reference
              router.envelope.sender << RouteResponse[hops, ignore_nodes, ignore_channels]
            end
            [self, data]
          rescue Lightning::Exceptions::RouteNotFound => e
            log(Logger::DEBUG, 'router_state', 'Route to the final node is not found. Retry after a while')
            log(Logger::DEBUG, 'router_state', e.message)
            [self, data]
          end
        when Lightning::Router::Messages::RequestGossipQuery
          transport = message.conn
          remote_node_id = message.remote_node_id
          transport << Queries.make_gossip_timestamp_filter(context.node_params)
          unless data[:query_channel_ranges][remote_node_id]
            transport << Queries.make_query_channel_range(context.node_params)
            data[:query_channel_ranges][remote_node_id] = true
          end
          [self, data]
        when Lightning::Router::Messages::QueryMessage
          query = message.message
          transport = message.conn
          remote_node_id = message.remote_node_id
          case query
          when Lightning::Wire::LightningMessages::QueryChannelRange
            short_channel_ids = data[:channels].keys.sort.map do |short_channel_id |
              Lightning::Channel::ShortChannelId.parse(short_channel_id)
            end.select do |short_channel_id|
              short_channel_id.in?(query.first_blocknum, query.number_of_blocks)
            end
            # Lightning message is limited in 65535 bytes
            short_channel_ids.each_slice(8000) do |short_channel_ids|
              transport << Queries.make_reply_channel_range(query, short_channel_ids)
            end
          when Lightning::Wire::LightningMessages::QueryShortChannelIds
            short_channel_ids = Queries.decode_short_channel_ids(query.encoded_short_ids)
            short_channel_ids.map do |short_channel_id|
              data[:channels][short_channel_id.to_i]
            end.compact.each do |channel|
              transport << channel
              desc = Announcements.to_channel_desc(channel)
              data[:updates][desc]&.tap { |update| transport << update }
            end
            transport << Queries.make_reply_short_channel_ids_end(query)
          when Lightning::Wire::LightningMessages::ReplyChannelRange
            data[:query_channel_ranges][remote_node_id] = false
            short_channel_ids = Queries.decode_short_channel_ids(query.encoded_short_ids)
            required = short_channel_ids - data[:channels].keys.map do |id|
              Lightning::Channel::ShortChannelId.parse(id)
            end
            unless data[:query_short_channel_ids][remote_node_id]
              transport << Queries.make_query_short_channel_ids(context.node_params, required)
              data[:query_short_channel_ids][remote_node_id] = true
            end
          when Lightning::Wire::LightningMessages::ReplyShortChannelIdsEnd
            data[:query_short_channel_ids][remote_node_id] = false
          end
          [self, data]
        when Lightning::Router::Messages::InitialSync
          # TODO: Implement
          [self, data]
        end
      end

      def related?(channel, node_id)
        node_id == channel.node_id_1 || node_id == channel.node_id_2
      end
    end
  end
end
