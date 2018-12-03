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
    class PascalString < ::Protobuf::Message; end
    class PublicKey < ::Protobuf::Message; end
    class PrivateKey < ::Protobuf::Message; end
    class Signature < ::Protobuf::Message; end


    ##
    # Message Fields
    #
    class PascalString
      optional :uint32, :length, 1, :".lightning.wire.bits" => 16
      optional :string, :value, 2
    end

    class PublicKey
      optional :bytes, :value, 1, :".lightning.wire.length" => 33
    end

    class PrivateKey
      optional :bytes, :value, 1, :".lightning.wire.length" => 32
    end

    class Signature
      optional :bytes, :r, 1, :".lightning.wire.length" => 32
      optional :bytes, :s, 2, :".lightning.wire.length" => 32
    end


    ##
    # Extended Message Fields
    #
    class ::Google::Protobuf::FieldOptions < ::Protobuf::Message
      optional :uint32, :".lightning.wire.bits", 50001, :extension => true
      optional :uint32, :".lightning.wire.length", 50002, :extension => true
    end

  end

end

