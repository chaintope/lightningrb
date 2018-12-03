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
    class Init < ::Protobuf::Message; end


    ##
    # Message Fields
    #
    class Init
      optional :uint32, :type, 1, :".lightning.wire.bits" => 16
      optional ::Lightning::Wire::PascalString, :globalfeatures, 2
      optional ::Lightning::Wire::PascalString, :localfeatures, 3
    end

  end

end

