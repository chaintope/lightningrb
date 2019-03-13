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
        class QueryShortChannelIds < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class QueryShortChannelIds
          optional :string, :chain_hash, 1, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :string, :encoded_short_ids, 5, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

