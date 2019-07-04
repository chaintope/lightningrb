# frozen_string_literal: true

require 'lightning/wire/lightning_messages/lightning_message.pb'

module Lightning
  module Wire
    module LightningMessages
      class LightningMessage < Lightning::Wire::LightningMessages::Generated::LightningMessage
        def self.load(payload)
          type = payload.unpack('n').first
          clazz = message_classes.select{|clazz| clazz.const_get('TYPE') == type}.first
          return nil unless clazz
          clazz.load(payload)
        end

        def self.message_classes
          [
            Init,
            Error,
            Ping,
            Pong,
            OpenChannel,
            AcceptChannel,
            FundingCreated,
            FundingSigned,
            FundingLocked,
            Shutdown,
            ClosingSigned,
            UpdateAddHtlc,
            UpdateFulfillHtlc,
            UpdateFailHtlc,
            UpdateFailMalformedHtlc,
            CommitmentSigned,
            RevokeAndAck,
            UpdateFee,
            ChannelReestablish,
            AnnouncementSignatures,
            ChannelAnnouncement,
            NodeAnnouncement,
            ChannelUpdate,
            GossipTimestampFilter,
            QueryChannelRange,
            QueryShortChannelIds,
            ReplyChannelRange,
            ReplyShortChannelIdsEnd
          ] + extension_message_classes
        end

        def self.extension_message_classes
          []
        end
      end
    end
  end
end
