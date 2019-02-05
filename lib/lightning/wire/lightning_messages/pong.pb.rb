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
        class Pong < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class Pong
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :ignored, 2, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

