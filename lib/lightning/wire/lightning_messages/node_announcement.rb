# frozen_string_literal: true

require 'lightning/wire/lightning_messages/node_announcement.pb'

module Lightning
  module Wire
    module LightningMessages
      class NodeAnnouncement < Lightning::Wire::LightningMessages::Generated::NodeAnnouncement
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
        include Lightning::Wire::LightningMessages
        include Lightning::Wire::LightningMessages::RoutingMessage
        TYPE = 257

        def initialize(fields = {})
          super(fields.merge(type: TYPE))
        end

        def valid?
          true
        end

        def valid_signature?
          Bitcoin::Key.new(pubkey: node_id).verify(signature.value.htb, witness)
        end

        def older_than?(other)
          other.timestamp >= timestamp
        end

        def parsed_addresses
          @parsed_addresses ||= parse_address(addresses)
        end

        def parse_address(addresses_as_string)
          puts addresses_as_string
          stream = StringIO.new(addresses_as_string.htb)
          addresses = []
          while !stream.eof?
            type = stream.read(1).unpack("C").first
            puts type
            case type
            when 0x01
              ipv4_addr = stream.read(4).unpack("a4").first
              ipv4_addr = IPAddr.ntop(ipv4_addr)
              port = stream.read(2).unpack('n').first
              address = Lightning::Wire::LightningMessages::Generated::IP4.new(
                ipv4_addr: ipv4_addr,
                port: port
              )
            when 0x02
              ipv6_addr = stream.read(16).unpack("a16").first
              ipv6_addr = IPAddr.ntop(ipv6_addr)
              port = stream.read(2).unpack('n').first
              address = Lightning::Wire::LightningMessages::Generated::IP6.new(
                ipv6_addr: ipv6_addr,
                port: port
              )
            when 0x03
              onion_addr = stream.read(10).unpack("a10").first
              port = stream.read(2).unpack('n').first
              address = Lightning::Wire::LightningMessages::Generated::Tor2.new(
                onion_addr: onion_addr,
                port: port
              )
            when 0x04
              onion_addr = stream.read(35).unpack("a35").first
              port = stream.read(2).unpack('n').first
              address = Lightning::Wire::LightningMessages::Generated::Tor3.new(
                onion_addr: onion_addr,
                port: port
              )
            end
            addresses << address
          end
          addresses
        end

        def witness
          self.class.witness(features, timestamp, node_id, node_rgb_color, node_alias, addresses)
        end

        def self.witness(features, timestamp, node_id, node_rgb_color, node_alias, addresses)
          witness = NodeAnnouncementWitness.new(
            features: features,
            timestamp: timestamp,
            node_id: node_id,
            node_rgb_color: node_rgb_color,
            node_alias: node_alias,
            addresses: addresses
          )
          stream = StringIO.new
          Protobuf::Encoder.encode(witness, stream)
          Bitcoin.double_sha256(stream.string)
        end

        def to_json
          to_h.slice(:node_id, :node_rgb_color,:node_alias, :addresses).to_json
        end
      end

      class NodeAnnouncementWitness < Lightning::Wire::LightningMessages::Generated::NodeAnnouncementWitness
        include Lightning::Wire::Serialization
        extend Lightning::Wire::Serialization
      end
    end
  end
end
