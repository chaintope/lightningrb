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

  end

end

