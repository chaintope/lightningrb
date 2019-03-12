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
        class FundingCreated < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class FundingCreated
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :temporary_channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :string, :funding_txid, 3, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint32, :funding_output_index, 4, :".lightning.wire.bits" => 16
          optional ::Lightning::Wire::Signature, :signature, 5
        end

      end

    end

  end

end

