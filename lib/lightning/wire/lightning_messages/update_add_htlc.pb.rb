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
        class UpdateAddHtlc < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class UpdateAddHtlc
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :id, 3
          optional :uint64, :amount_msat, 4
          optional :string, :payment_hash, 5, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint32, :cltv_expiry, 6
          optional :string, :onion_routing_packet, 7, :".lightning.wire.length" => 1366, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

