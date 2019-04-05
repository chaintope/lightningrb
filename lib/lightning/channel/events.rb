# frozen_string_literal: true

module Lightning
  module Channel
    module Events
      include Lightning::Utils::Algebrick
      include Lightning::Wire::LightningMessages
      ChannelEvents = Algebrick.type do
        ChannelCreated = type do
          fields! channel: Concurrent::Actor::Reference,
                  peer: Concurrent::Actor::Reference,
                  remote_node_id: String,
                  is_funder: Numeric,
                  temporary_channel_id: String
        end
        ChannelRestored = type do
          fields! channel: Concurrent::Actor::Reference,
                  peer: Concurrent::Actor::Reference,
                  remote_node_id: String,
                  is_funder: Numeric,
                  channel_id: String,
                  current_data: Lightning::Channel::Messages::HasCommitments
        end
        ChannelIdAssigned = type do
          fields! channel: Concurrent::Actor::Reference,
                  remote_node_id: String,
                  temporary_channel_id: String,
                  channel_id: String
        end
        ShortChannelIdAssigned = type do
          fields! channel: Concurrent::Actor::Reference,
                  channel_id: String,
                  short_channel_id: Numeric
        end
        LocalChannelUpdate = type do
          fields! channel: Concurrent::Actor::Reference,
                  channel_id: String,
                  short_channel_id: Numeric,
                  remote_node_id: String,
                  channel_announcement: Algebrick::Maybe[ChannelAnnouncement],
                  channel_update: ChannelUpdate
        end
        LocalChannelDown = type do
          fields! channel: Concurrent::Actor::Reference,
                  channel_id: String,
                  short_channel_id: Numeric,
                  remote_node_id: String
        end
        ChannelStateChanged = type do
          fields! channel: Concurrent::Actor::Reference,
                  peer: Concurrent::Actor::Reference,
                  remote_node_id: String,
                  previous_state: Object,
                  current_state: Object,
                  current_data: Object
        end
        ChannelSignatureReceived = type do
          fields! channel: Concurrent::Actor::Reference,
                  commitments: Lightning::Channel::Messages::Commitments
        end
        ChannelClosed = type do
          fields! channel: Concurrent::Actor::Reference,
                  channel_id: String
        end
        variants  ChannelCreated,
                  ChannelRestored,
                  ChannelIdAssigned,
                  ShortChannelIdAssigned,
                  LocalChannelUpdate,
                  LocalChannelDown,
                  ChannelSignatureReceived,
                  ChannelClosed
      end
    end
  end
end
