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
        class ChannelReestablish < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ChannelReestablish
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional :string, :channel_id, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :next_local_commitment_number, 3
          optional :uint64, :next_remote_revocation_number, 4
          optional :string, :your_last_per_commitment_secret, 5, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :string, :my_current_per_commitment_point, 6, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

