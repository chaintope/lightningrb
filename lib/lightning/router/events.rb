# frozen_string_literal: true

module Lightning
  module Router
    module Events
      include Lightning::Utils::Algebrick
      include Lightning::Wire::LightningMessages

      NodeDiscovered = type do
        fields! node: NodeAnnouncement
      end
      NodeUpdated = type do
        fields! node: NodeAnnouncement
      end
      NodeLost = type do
        fields! node_id: String
      end

      ChannelDiscovered = type do
        fields! channel: ChannelAnnouncement,
                capacity: Numeric
      end
      ChannelLost = type do
        fields! short_channel_id: Numeric
      end
      ChannelUpdated = type do
        fields! channel: ChannelUpdate
      end
    end
  end
end
