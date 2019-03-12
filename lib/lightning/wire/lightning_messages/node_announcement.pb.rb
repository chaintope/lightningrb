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
        class NodeAnnouncement < ::Protobuf::Message; end
        class NodeAnnouncementWitness < ::Protobuf::Message; end
        class Address < ::Protobuf::Message; end
        class IP4 < ::Protobuf::Message; end
        class IP6 < ::Protobuf::Message; end
        class Tor2 < ::Protobuf::Message; end
        class Tor3 < ::Protobuf::Message; end


        ##
        # Message Fields
        #
        class NodeAnnouncement
          optional :uint32, :type, 1, :".lightning.wire.bits" => 16
          optional ::Lightning::Wire::Signature, :signature, 2
          optional :string, :features, 3, :".lightning.wire.hex" => true
          optional :uint32, :timestamp, 4
          optional :string, :node_id, 5, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :uint32, :node_rgb_color, 6, :".lightning.wire.bits" => 24
          optional :string, :node_alias, 7, :".lightning.wire.length" => 32
          optional :string, :addresses, 8, :".lightning.wire.hex" => true
        end

        class NodeAnnouncementWitness
          optional :string, :features, 1, :".lightning.wire.hex" => true
          optional :uint32, :timestamp, 2
          optional :string, :node_id, 3, :".lightning.wire.length" => 33, :".lightning.wire.hex" => true
          optional :uint32, :node_rgb_color, 4, :".lightning.wire.bits" => 24
          optional :string, :node_alias, 5, :".lightning.wire.length" => 32
          optional :string, :addresses, 6, :".lightning.wire.hex" => true
        end

        class Address
          optional ::Lightning::Wire::LightningMessages::Generated::IP4, :ip4, 1
          optional ::Lightning::Wire::LightningMessages::Generated::IP6, :ip6, 2
          optional ::Lightning::Wire::LightningMessages::Generated::Tor2, :tor2, 3
          optional ::Lightning::Wire::LightningMessages::Generated::Tor3, :tor3, 4
        end

        class IP4
          optional :string, :ipv4_addr, 1, :".lightning.wire.length" => 4
          optional :uint32, :port, 2, :".lightning.wire.bits" => 16
        end

        class IP6
          optional :string, :ipv6_addr, 1, :".lightning.wire.length" => 16
          optional :uint32, :port, 2, :".lightning.wire.bits" => 16
        end

        class Tor2
          optional :string, :onion_addr, 1, :".lightning.wire.length" => 10
          optional :uint32, :port, 2, :".lightning.wire.bits" => 16
        end

        class Tor3
          optional :string, :onion_addr, 1, :".lightning.wire.length" => 35
          optional :uint32, :port, 2, :".lightning.wire.bits" => 16
        end

      end

    end

  end

end

