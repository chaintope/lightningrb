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
  module Channel
    module Generated
      ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

      ##
      # Message Classes
      #
      class ShortChannelId < ::Protobuf::Message; end


      ##
      # Message Fields
      #
      class ShortChannelId
        optional :uint32, :block_height, 1, :".lightning.wire.bits" => 24
        optional :uint32, :tx_index, 2, :".lightning.wire.bits" => 24
        optional :uint32, :output_index, 3, :".lightning.wire.bits" => 16
      end

    end

  end

end

