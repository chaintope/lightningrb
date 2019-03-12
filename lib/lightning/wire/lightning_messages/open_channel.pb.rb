# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'


##
# Imports
#
require 'lightning/wire/types.pb'

module Lightning
  module Wire
    module LightningMessages
      module Generated
        ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

        ##
        # Message Classes
        #
        class OpenChannel < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class OpenChannel
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :chain_hash, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :string, :temporary_channel_id, 3, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :funding_satoshis, 4
          optional :uint64, :push_msat, 5
          optional :uint64, :dust_limit_satoshis, 6
          optional :uint64, :max_htlc_value_in_flight_msat, 7
          optional :uint64, :channel_reserve_satoshis, 8
          optional :uint64, :htlc_minimum_msat, 9
          optional :uint32, :feerate_per_kw, 10
          optional :uint32, :to_self_delay, 11, :".lightning.wire.bits" => 16
          optional :uint32, :max_accepted_htlcs, 12, :".lightning.wire.bits" => 16
          optional :string, :funding_pubkey, 13, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :revocation_basepoint, 14, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :payment_basepoint, 15, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :delayed_payment_basepoint, 16, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :htlc_basepoint, 17, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :first_per_commitment_point, 18, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :uint32, :channel_flags, 19, :".lightning.wire.bits" => 8
          optional :string, :shutdown_scriptpubkey, 20, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

