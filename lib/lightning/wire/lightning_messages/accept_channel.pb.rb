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
        class AcceptChannel < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class AcceptChannel
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :temporary_channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :dust_limit_satoshis, 3
          optional :uint64, :max_htlc_value_in_flight_msat, 4
          optional :uint64, :channel_reserve_satoshis, 5
          optional :uint64, :htlc_minimum_msat, 6
          optional :uint32, :minimum_depth, 7
          optional :uint32, :to_self_delay, 8, :".lightning.wire.bits" => 16
          optional :uint32, :max_accepted_htlcs, 9, :".lightning.wire.bits" => 16
          optional :string, :funding_pubkey, 10, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :revocation_basepoint, 11, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :payment_basepoint, 12, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :delayed_payment_basepoint, 13, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :htlc_basepoint, 14, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :first_per_commitment_point, 15, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :shutdown_scriptpubkey, 16, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

