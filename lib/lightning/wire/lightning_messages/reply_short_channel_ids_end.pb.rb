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
        class ReplyShortChannelIdsEnd < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ReplyShortChannelIdsEnd
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :chain_hash, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint32, :complete, 3, :".lightning.wire.bits" => 8
        end

      end

    end

  end

end

