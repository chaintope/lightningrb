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
        class ChannelAnnouncement < ::Protobuf::Message; end
        class ChannelAnnouncementWitness < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class ChannelAnnouncement
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional ::Lightning::Wire::Signature, :node_signature_1, 2
          optional ::Lightning::Wire::Signature, :node_signature_2, 3
          optional ::Lightning::Wire::Signature, :bitcoin_signature_1, 4
          optional ::Lightning::Wire::Signature, :bitcoin_signature_2, 5
          optional :string, :features, 6, :".lightning.wire.hex" => true
          optional :string, :chain_hash, 7, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :short_channel_id, 8
          optional :string, :node_id_1, 9, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :node_id_2, 10, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :bitcoin_key_1, 11, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :bitcoin_key_2, 12, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
        end

        class ChannelAnnouncementWitness
          optional :string, :features, 1, :".lightning.wire.hex" => true
          optional :string, :chain_hash, 2, :".lightning.wire.length" => 32, :".lightning.wire.hex" => true
          optional :uint64, :short_channel_id, 3
          optional :string, :node_id_1, 4, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :node_id_2, 5, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :bitcoin_key_1, 6, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :string, :bitcoin_key_2, 7, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
        end

      end

    end

  end

end

