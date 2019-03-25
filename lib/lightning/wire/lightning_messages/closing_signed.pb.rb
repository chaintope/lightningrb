# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'


##
# Imports
#
require 'lightning/wire/types.pb'
require 'lightning/wire/signature.pb'

module Lightning
  module Wire
    module LightningMessages
      module Generated
        ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

        ##
        # Message Classes
        #
        class ClosingSigned < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ClosingSigned
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :fee_satoshis, 3
          optional ::Lightning::Wire::Signature, :signature, 4
        end

      end

    end

  end

end

