# encoding: utf-8

##
# This file is auto-generated. DO NOT EDIT!
#
require 'protobuf'


##
# Imports
#
require 'google/protobuf/descriptor.pb'

module Lightning
  module Wire
    ::Protobuf::Optionable.inject(self) { ::Google::Protobuf::FileOptions }

    ##
    # Message Classes
    #
    class Signature < ::Protobuf::Message; end


    ##
    # Message Fields
    #
    class Signature
      optional :string, :value, 1, :".lightning.wire.hex" => true
    end


    ##
    # Extended Message Fields
    #
    class ::Google::Protobuf::MessageOptions < ::Protobuf::Message
      optional :uint32, :".lightning.wire.type", 50001, :extension => true
    end

    class ::Google::Protobuf::FieldOptions < ::Protobuf::Message
      optional :uint32, :".lightning.wire.bits", 60001, :extension => true
      optional :uint32, :".lightning.wire.length", 60002, :extension => true
      optional :bool, :".lightning.wire.hex", 60003, :extension => true
    end

  end

end

