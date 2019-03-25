# frozen_string_literal: true

module Lightning
  module Router
    module Messages
      # nodes : key is public key(String)
      #         value is NodeAnnouncement
      # channels: key is short channel id (Numeric)
      #           value is ChannelAnnouncement
      # updates : key is ChannelDesc
      #           value is ChannelUpdate
      # query_channel_ranges: key is node_id
      #                       value is true/false
      # query_short_channel_ids: key is node_id
      #                          value is true/false
      Data = Algebrick.type do
        fields! nodes: Hash,
                channels: Hash,
                updates: Hash,
                query_channel_ranges: Hash,
                query_short_channel_ids: Hash
      end

      Timeout = Algebrick.atom

      Rebroadcast = Algebrick.type do
        fields! message: Lightning::Wire::LightningMessages::RoutingMessage
      end

      module Data
        def copy(nodes: self[:nodes], channels: self[:channels], updates: self[:updates])
          Data[nodes, channels, updates, self[:query_channel_ranges], self[:query_short_channel_ids]]
        end
      end

      ChannelDesc = Algebrick.type do
        fields! id: Numeric,
                a: String,
                b: String
      end

      Hop = Algebrick.type do
        fields! node_id: String,
                next_node_id: String,
                last_update: Lightning::Wire::LightningMessages::ChannelUpdate
      end

      RouteRequest = Algebrick.type do
        fields! source: String,
                target: String,
                assisted_routes: Array
      end

      RouteResponse = Algebrick.type do
        fields! hops: Array,
                ignore_nodes: Array,
                ignore_channels: Array
      end

      class RequestGossipQuery
        attr_reader :conn, :remote_node_id
        def initialize(conn, remote_node_id)
          @conn = conn
          @remote_node_id = remote_node_id
        end
      end

      class QueryMessage
        attr_reader :conn, :remote_node_id, :message
        def initialize(conn, remote_node_id, message)
          @conn = conn
          @remote_node_id = remote_node_id
          @message = message
        end
      end

      class InitialSync
        attr_reader :conn
        def initialize(conn: nil)
          @conn = conn
        end
      end
    end
  end
end
