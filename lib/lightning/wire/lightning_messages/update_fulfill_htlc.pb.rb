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
        class UpdateFulfillHtlc < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class UpdateFulfillHtlc
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :id, 3
          optional :string, :payment_preimage, 4, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

