# frozen_string_literal: true

require 'lightning/wire/lightning_messages/lightning_message.pb'

module Lightning
  module Wire
    module LightningMessages
      def lightning?
        classes = [
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
        ]
        classes.include?(self.class)
      end

      def to_s
        inspect
      end

      module HasTemporaryChannelId
      end

      module HasChannelId
      end

      module UpdateMessage
      end

      module RoutingMessage
      end

      class LightningMessage < Lightning::Wire::LightningMessages::Generated::LightningMessage
        def self.load(payload)
          type = payload.unpack('n').first
          clazz = [
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
          ].select{|clazz| clazz.const_get('TYPE') == type}.first
          return nil unless clazz
          clazz.load(payload)
        end
      end

      require 'lightning/wire/lightning_messages/init'
      require 'lightning/wire/lightning_messages/error'
      require 'lightning/wire/lightning_messages/ping'
      require 'lightning/wire/lightning_messages/pong'

      require 'lightning/wire/lightning_messages/open_channel'
      require 'lightning/wire/lightning_messages/accept_channel'
      require 'lightning/wire/lightning_messages/funding_created'
      require 'lightning/wire/lightning_messages/funding_signed'
      require 'lightning/wire/lightning_messages/funding_locked'
      require 'lightning/wire/lightning_messages/shutdown'
      require 'lightning/wire/lightning_messages/closing_signed'

      require 'lightning/wire/lightning_messages/update_add_htlc'
      require 'lightning/wire/lightning_messages/update_fulfill_htlc'
      require 'lightning/wire/lightning_messages/update_fail_htlc'
      require 'lightning/wire/lightning_messages/update_fail_malformed_htlc'
      require 'lightning/wire/lightning_messages/commitment_signed'
      require 'lightning/wire/lightning_messages/revoke_and_ack'
      require 'lightning/wire/lightning_messages/update_fee'
      require 'lightning/wire/lightning_messages/channel_reestablish'

      require 'lightning/wire/lightning_messages/announcement_signatures'
      require 'lightning/wire/lightning_messages/channel_announcement'
      require 'lightning/wire/lightning_messages/node_announcement'
      require 'lightning/wire/lightning_messages/channel_update'
    end
  end
end
