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
        class ChannelUpdate < ::Protobuf::Message; end
        class ChannelUpdateWitness < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ChannelUpdate
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional ::Lightning::Wire::Signature, :signature, 2
          optional :string, :chain_hash, 3, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :short_channel_id, 4
          optional :uint32, :timestamp, 5
          optional :string, :message_flags, 6, :".lightning.wire.length" => 1, :".lightning.wire.hex" => true
          optional :string, :channel_flags, 7, :".lightning.wire.length" => 1, :".lightning.wire.hex" => true
          optional :uint32, :cltv_expiry_delta, 8, :".lightning.wire.bits" => 16
          optional :uint64, :htlc_minimum_msat, 9
          optional :uint32, :fee_base_msat, 10
          optional :uint32, :fee_proportional_millionths, 11
          optional :uint64, :htlc_maximum_msat, 12
        end

        class ChannelUpdateWitness
          optional :string, :chain_hash, 1, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :short_channel_id, 2
          optional :uint32, :timestamp, 3
          optional :string, :message_flags, 4, :".lightning.wire.length" => 1, :".lightning.wire.hex" => true
          optional :string, :channel_flags, 5, :".lightning.wire.length" => 1, :".lightning.wire.hex" => true
          optional :uint32, :cltv_expiry_delta, 6, :".lightning.wire.bits" => 16
          optional :uint64, :htlc_minimum_msat, 7
          optional :uint32, :fee_base_msat, 8
          optional :uint32, :fee_proportional_millionths, 9
          optional :uint64, :htlc_maximum_msat, 10
        end

      end

    end

  end

end

