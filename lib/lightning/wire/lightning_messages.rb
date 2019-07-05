# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      def to_s
        inspect
      end

      module HasTemporaryChannelId
      end

      module HasChannelId
      end

      module OpenMessage
      end

      module UpdateMessage
      end

      module RoutingMessage
      end

      module GossipQuery
      end

      autoload :LightningMessage, 'lightning/wire/lightning_messages/lightning_message'

      autoload :Init, 'lightning/wire/lightning_messages/init'
      autoload :Error, 'lightning/wire/lightning_messages/error'
      autoload :Ping, 'lightning/wire/lightning_messages/ping'
      autoload :Pong, 'lightning/wire/lightning_messages/pong'

      autoload :OpenChannel, 'lightning/wire/lightning_messages/open_channel'
      autoload :AcceptChannel, 'lightning/wire/lightning_messages/accept_channel'
      autoload :FundingCreated, 'lightning/wire/lightning_messages/funding_created'
      autoload :FundingSigned, 'lightning/wire/lightning_messages/funding_signed'
      autoload :FundingLocked, 'lightning/wire/lightning_messages/funding_locked'
      autoload :Shutdown, 'lightning/wire/lightning_messages/shutdown'
      autoload :ClosingSigned, 'lightning/wire/lightning_messages/closing_signed'

      autoload :UpdateAddHtlc, 'lightning/wire/lightning_messages/update_add_htlc'
      autoload :UpdateFulfillHtlc, 'lightning/wire/lightning_messages/update_fulfill_htlc'
      autoload :UpdateFailHtlc, 'lightning/wire/lightning_messages/update_fail_htlc'
      autoload :UpdateFailMalformedHtlc, 'lightning/wire/lightning_messages/update_fail_malformed_htlc'
      autoload :CommitmentSigned, 'lightning/wire/lightning_messages/commitment_signed'
      autoload :RevokeAndAck, 'lightning/wire/lightning_messages/revoke_and_ack'
      autoload :UpdateFee, 'lightning/wire/lightning_messages/update_fee'
      autoload :ChannelReestablish, 'lightning/wire/lightning_messages/channel_reestablish'

      autoload :AnnouncementSignatures, 'lightning/wire/lightning_messages/announcement_signatures'
      autoload :ChannelAnnouncement, 'lightning/wire/lightning_messages/channel_announcement'
      autoload :NodeAnnouncement, 'lightning/wire/lightning_messages/node_announcement'
      autoload :ChannelUpdate, 'lightning/wire/lightning_messages/channel_update'

      autoload :GossipTimestampFilter, 'lightning/wire/lightning_messages/gossip_timestamp_filter'
      autoload :QueryChannelRange, 'lightning/wire/lightning_messages/query_channel_range'
      autoload :QueryShortChannelIds, 'lightning/wire/lightning_messages/query_short_channel_ids'
      autoload :ReplyChannelRange, 'lightning/wire/lightning_messages/reply_channel_range'
      autoload :ReplyShortChannelIdsEnd, 'lightning/wire/lightning_messages/reply_short_channel_ids_end'
    end
  end
end
