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
        class CommitmentSigned < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class CommitmentSigned
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional ::Lightning::Wire::Signature, :signature, 3
          repeated ::Lightning::Wire::Signature, :htlc_signature, 4
        end

      end

    end

  end

end

