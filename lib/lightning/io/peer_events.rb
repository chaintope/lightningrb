# frozen_string_literal: true

module Lightning
  module IO
    module PeerEvents
      include Algebrick
      include Lightning::Wire::LightningMessages
      Events = Algebrick.type do
        Timeout = atom
        Reconnect = atom
        OpenChannel = type do
          fields! remote_node_id: String,
                  funding_satoshis: Numeric,
                  push_msat: Numeric,
                  channel_flags: Numeric,
                  option: Hash
        end
        Connect = type do
          fields! remote_node_id: String,
                  host: String,
                  port: Numeric,
                  option: Hash
        end
        variants Timeout, Reconnect, OpenChannel, Connect
      end

      TemporaryChannelId = Algebrick.type { fields! id: String }
      FinalChannelId = Algebrick.type { fields! id: String }
      ChannelId = Algebrick.type do
        variants TemporaryChannelId, FinalChannelId
        fields! id: String
      end

      Data = Algebrick.type do
        URI = type do
          fields! host: String,
                  port: Numeric
        end
        DisconnectedData = type do
          fields! address_opt: type { variants Algebrick::None, URI }
        end
        InitializingData = type do
          fields! address_opt: type { variants Algebrick::None, URI },
                  transport: Concurrent::Actor::Reference,
                  origin_opt: type { variants Algebrick::None, Concurrent::Actor::Reference }
        end
        ConnectedData = type do
          fields! address_opt: type { variants Algebrick::None, URI },
                  transport: Concurrent::Actor::Reference,
                  remote_init: Init,
                  channels: Hash,
                  gossip_timestamp_filter: GossipTimestampFilter
        end
        variants DisconnectedData, InitializingData, ConnectedData
      end

      module ConnectedData
        def copy(gossip_timestamp_filter: self[:gossip_timestamp_filter])
          ConnectedData[
            self[:address_opt], self[:transport], self[:remote_init], self[:channels], gossip_timestamp_filter
          ]
        end
      end
    end
  end
end
