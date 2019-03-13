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
          optional :string, :chain_hash, 1, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint32, :complete, 2, :".lightning.wire.bits" => 8
        end

      end

    end

  end

end

