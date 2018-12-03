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
      Data = Algebrick.type do
        fields! nodes: Hash,
                channels: Hash,
                updates: Hash
      end

      module Data
        def copy(nodes: self[:nodes], channels: self[:channels], updates: self[:updates])
          Data[nodes, channels, updates]
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
    end
  end
end
