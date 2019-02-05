# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'


##
# Imports
#
require 'lightning/wire/types.pb'
require 'lightning/wire/lightning_messages/init.pb'
require 'lightning/wire/lightning_messages/error.pb'
require 'lightning/wire/lightning_messages/ping.pb'
require 'lightning/wire/lightning_messages/pong.pb'
require 'lightning/wire/lightning_messages/open_channel.pb'
require 'lightning/wire/lightning_messages/accept_channel.pb'
require 'lightning/wire/lightning_messages/funding_created.pb'
require 'lightning/wire/lightning_messages/funding_signed.pb'
require 'lightning/wire/lightning_messages/funding_locked.pb'
require 'lightning/wire/lightning_messages/shutdown.pb'
require 'lightning/wire/lightning_messages/closing_signed.pb'
require 'lightning/wire/lightning_messages/update_add_htlc.pb'
require 'lightning/wire/lightning_messages/update_fulfill_htlc.pb'
require 'lightning/wire/lightning_messages/update_fail_htlc.pb'
require 'lightning/wire/lightning_messages/update_fail_malformed_htlc.pb'
require 'lightning/wire/lightning_messages/commitment_signed.pb'
require 'lightning/wire/lightning_messages/revoke_and_ack.pb'
require 'lightning/wire/lightning_messages/update_fee.pb'
require 'lightning/wire/lightning_messages/channel_reestablish.pb'
require 'lightning/wire/lightning_messages/announcement_signatures.pb'
require 'lightning/wire/lightning_messages/channel_announcement.pb'
require 'lightning/wire/lightning_messages/node_announcement.pb'
require 'lightning/wire/lightning_messages/channel_update.pb'

module Lightning
  module Wire
    module LightningMessages
      module Generated
        ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

        ##
        # Message Classes
        #
        class LightningMessage < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class LightningMessage
          optional ::Lightning::Wire::LightningMessages::Generated::Init, :init, 1
          optional ::Lightning::Wire::LightningMessages::Generated::Error, :error, 2
          optional ::Lightning::Wire::LightningMessages::Generated::Ping, :ping, 3
          optional ::Lightning::Wire::LightningMessages::Generated::Pong, :pong, 4
          optional ::Lightning::Wire::LightningMessages::Generated::OpenChannel, :open_channel, 5
          optional ::Lightning::Wire::LightningMessages::Generated::AcceptChannel, :accept_channel, 6
          optional ::Lightning::Wire::LightningMessages::Generated::FundingCreated, :funding_created, 7
          optional ::Lightning::Wire::LightningMessages::Generated::FundingSigned, :funding_signed, 8
          optional ::Lightning::Wire::LightningMessages::Generated::FundingLocked, :funding_locked, 9
          optional ::Lightning::Wire::LightningMessages::Generated::Shutdown, :shutdown, 10
          optional ::Lightning::Wire::LightningMessages::Generated::ClosingSigned, :closing_signed, 11
          optional ::Lightning::Wire::LightningMessages::Generated::UpdateAddHtlc, :update_add_htlc, 12
          optional ::Lightning::Wire::LightningMessages::Generated::UpdateFulfillHtlc, :update_fulfill_htlc, 13
          optional ::Lightning::Wire::LightningMessages::Generated::UpdateFailHtlc, :update_fail_htlc, 14
          optional ::Lightning::Wire::LightningMessages::Generated::UpdateFailMalformedHtlc, :update_fail_malformed_htlc, 15
          optional ::Lightning::Wire::LightningMessages::Generated::CommitmentSigned, :commitment_signed, 16
          optional ::Lightning::Wire::LightningMessages::Generated::RevokeAndAck, :revoke_and_ack, 17
          optional ::Lightning::Wire::LightningMessages::Generated::UpdateFee, :update_fee, 18
          optional ::Lightning::Wire::LightningMessages::Generated::ChannelReestablish, :channel_reestablish, 19
          optional ::Lightning::Wire::LightningMessages::Generated::AnnouncementSignatures, :announcement_signatures, 20
          optional ::Lightning::Wire::LightningMessages::Generated::ChannelAnnouncement, :channel_announcement, 21
          optional ::Lightning::Wire::LightningMessages::Generated::NodeAnnouncement, :node_announcement, 22
          optional ::Lightning::Wire::LightningMessages::Generated::ChannelUpdate, :channel_update, 23
        end

      end

    end

  end

end

