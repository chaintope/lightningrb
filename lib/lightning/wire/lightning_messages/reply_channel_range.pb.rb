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
        class ReplyChannelRange < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ReplyChannelRange
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :chain_hash, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint32, :first_blocknum, 3
          optional :uint32, :number_of_blocks, 4
          optional :uint32, :complete, 5, :".lightning.wire.bits" => 8
          optional :string, :encoded_short_ids, 6, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

