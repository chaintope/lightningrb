# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      LightningMessage = Algebrick.type do
        Init = type do
          fields! gflen: Numeric,
                  globalfeatures: String,
                  lflen: Numeric,
                  localfeatures: String
        end
        Error = type do
          fields! channel_id: String,
                  len: Numeric,
                  data: String
        end
        Ping = type do
          fields! num_pong_bytes: Numeric,
                  byteslen: Numeric,
                  ignored: String
        end
        Pong = type do
          fields! byteslen: Numeric,
                  ignored: String
        end

        OpenChannel = type do
          fields! chain_hash: String,
                  temporary_channel_id: String,
                  funding_satoshis: Numeric,
                  push_msat: Numeric,
                  dust_limit_satoshis: Numeric,
                  max_htlc_value_in_flight_msat: Numeric,
                  channel_reserve_satoshis: Numeric,
                  htlc_minimum_msat: Numeric,
                  feerate_per_kw: Numeric,
                  to_self_delay: Numeric,
                  max_accepted_htlcs: Numeric,
                  funding_pubkey: String,
                  revocation_basepoint: String,
                  payment_basepoint: String,
                  delayed_payment_basepoint: String,
                  htlc_basepoint: String,
                  first_per_commitment_point: String,
                  channel_flags: Numeric
        end
        AcceptChannel = type do
          fields! temporary_channel_id: String,
                  dust_limit_satoshis: Numeric,
                  max_htlc_value_in_flight_msat: Numeric,
                  channel_reserve_satoshis: Numeric,
                  htlc_minimum_msat: Numeric,
                  minimum_depth: Numeric,
                  to_self_delay: Numeric,
                  max_accepted_htlcs: Numeric,
                  funding_pubkey: String,
                  revocation_basepoint: String,
                  payment_basepoint: String,
                  delayed_payment_basepoint: String,
                  htlc_basepoint: String,
                  first_per_commitment_point: String
        end
        FundingCreated = type do
          fields! temporary_channel_id: String,
                  funding_txid: String,
                  funding_output_index: Numeric,
                  signature: String
        end
        FundingSigned = type do
          fields! channel_id: String,
                  signature: String
        end
        FundingLocked = type do
          fields! channel_id: String,
                  next_per_commitment_point: String
        end

        Shutdown = type do
          fields! channel_id: String,
                  len: Numeric,
                  scriptpubkey: String
        end
        ClosingSigned = type do
          fields! channel_id: String,
                  fee_satoshis: Numeric,
                  signature: String
        end

        UpdateAddHtlc = type do
          fields! channel_id: String,
                  id: Numeric,
                  amount_msat: Numeric,
                  payment_hash: String,
                  cltv_expiry: Numeric,
                  onion_routing_packet: String
        end
        UpdateFulfillHtlc = type do
          fields! channel_id: String,
                  id: Numeric,
                  payment_preimage: String
        end
        UpdateFailHtlc = type do
          fields! channel_id: String,
                  id: Numeric,
                  len: Numeric,
                  reason: String
        end
        UpdateFailMalformedHtlc = type do
          fields! channel_id: String,
                  id: Numeric,
                  sha256_of_onion: String,
                  failure_code: Numeric
        end
        CommitmentSigned = type do
          fields! channel_id: String,
                  signature: String,
                  num_htlcs: Numeric,
                  htlc_signature: Array
        end
        RevokeAndAck = type do
          fields! channel_id: String,
                  per_commitment_secret: String,
                  next_per_commitment_point: String
        end
        UpdateFee = type do
          fields! channel_id: String,
                  feerate_per_kw: Numeric
        end
        ChannelReestablish = type do
          fields! channel_id: String,
                  next_local_commitment_number: Numeric,
                  next_remote_revocation_number: Numeric,
                  your_last_per_commitment_secret: String,
                  my_current_per_commitment_point: String
        end
        AnnouncementSignatures = type do
          fields! channel_id: String,
                  short_channel_id: Numeric,
                  node_signature: String,
                  bitcoin_signature: String
        end
        ChannelAnnouncement = type do
          fields! node_signature_1: String,
                  node_signature_2: String,
                  bitcoin_signature_1: String,
                  bitcoin_signature_2: String,
                  len: Numeric,
                  features: String,
                  chain_hash: String,
                  short_channel_id: Numeric,
                  node_id_1: String,
                  node_id_2: String,
                  bitcoin_key_1: String,
                  bitcoin_key_2: String
        end
        NodeAnnouncement = type do
          fields! signature: String,
                  flen: Numeric,
                  features: String,
                  timestamp: Numeric,
                  node_id: String,
                  node_rgb_color: Array,
                  node_alias: String,
                  addrlen: Numeric,
                  addresses: Array
        end
        ChannelUpdate = type do
          fields! signature: String,
                  chain_hash: String,
                  short_channel_id: Numeric,
                  timestamp: Numeric,
                  message_flags: Numeric,
                  channel_flags: Numeric,
                  cltv_expiry_delta: Numeric,
                  htlc_minimum_msat: Numeric,
                  fee_base_msat: Numeric,
                  fee_proportional_millionths: Numeric
        end

        variants  Init,
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
                  ChannelUpdate
      end
      HasTemporaryChannelId = Algebrick.type do
        variants OpenChannel, AcceptChannel, FundingCreated
      end
      HasChannelId = Algebrick.type do
        variants  FundingSigned,
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
                  AnnouncementSignatures
      end
      UpdateMessage = Algebrick.type do
        variants  UpdateAddHtlc,
                  UpdateFulfillHtlc,
                  UpdateFailHtlc,
                  UpdateFailMalformedHtlc,
                  UpdateFee
      end
      RoutingMessage = Algebrick.type do
        variants  AnnouncementSignatures,
                  ChannelAnnouncement,
                  ChannelUpdate,
                  NodeAnnouncement
      end

      def self.parse_message_type(type)
        LightningMessage.variants.find do |t|
          t.to_type == type
        end
      end

      # @return DER format binary string
      def self.wire2der(signature)
        # TODO: raise Lightning::Crypto::DER::SignatureLengthError.new unless signature.size == 64
        r = signature[0...32]
        s = signature[32...64]
        sig = Lightning::Crypto::DER.encode(r, s)
        sig.bth
      end

      # @return binary string
      def self.der2wire(der)
        # TODO: raise Lightning::Crypto::DER::InvalidDERError.new unless Lightning::Crypto::DER.valid?(der)
        Lightning::Crypto::DER.decode(der).htb
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

  module Utils
    class Serializer
      def lightning_message
        fields << LightningMessage.new
        self
      end

      class LightningMessage
        def unpack(payload)
          type, rest = payload.unpack('na*')
          type = Lightning::Wire::LightningMessages.parse_message_type(type)
          type.unpack(rest)
        end

        def pack(value)
          value.pack
        end
      end
    end
  end
end
