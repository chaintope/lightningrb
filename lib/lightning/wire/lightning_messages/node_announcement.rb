# frozen_string_literal: true

module Lightning
  module Wire
    module LightningMessages
      module NodeAnnouncement
        def self.load(payload)
          _, signature, flen, rest = payload.unpack('na64na*')
          signature = LightningMessages.wire2der(signature)
          features, timestamp, node_id, r, g, b, node_alias, len, rest = rest.unpack("a#{flen}NH66C3a32na*")
          node_alias, = node_alias.unpack('Z32')
          rest, = rest.unpack("a#{len}")
          addresses = []
          while rest.bytesize >= 1
            address_descriptor, rest = rest.unpack('Ca*')
            case address_descriptor
            when 0
              addresses << ''
            when 1
              host, port, rest = rest.unpack('Nna*')
              addresses << "#{to_ipv4(host)}:#{port}"
            else
              # TODO: support for ipv6, tor v2 onion, tor v3 onion
            end
          end
          new(signature, flen, features, timestamp, node_id, [r, g, b], node_alias, addresses.size, addresses)
        end

        def self.to_ipv4(i)
          IPAddr.new(i, Socket::AF_INET).to_s
        end

        def self.to_type
          Lightning::Wire::LightningMessageTypes::NODE_ANNOUNCEMENT
        end

        def to_payload
          payload = +''
          payload << [NodeAnnouncement.to_type].pack('n')
          payload << LightningMessages.der2wire(self[:signature].htb)
          payload << witness_data
          payload
        end

        def valid?
          return false unless self[:flen] == self[:features].bytesize
          true
        end

        def valid_signature?
          Bitcoin::Key.new(pubkey: self[:node_id]).verify(self[:signature].htb, witness)
        end

        def older_than?(other)
          other[:timestamp] >= self[:timestamp]
        end

        def witness_data
          payload = +''
          payload << [self[:flen]].pack('n')
          payload << self[:features]
          payload << [self[:timestamp]].pack('N')
          payload << self[:node_id].htb
          payload << self[:node_rgb_color].pack('C3')
          payload << [self[:node_alias]].pack('Z32')
          # TODO: support for ipv6, tor v2 onion, tor v3 onion
          payload << [7 * self[:addrlen]].pack('n')
          self[:addresses].each do |address|
            # TODO: support for ipv6, tor v2 onion, tor v3 onion
            host, port = address.split(':')
            payload << [1, IPAddr.new(host).to_i, port.to_i].pack('CNn')
          end
          payload
        end

        def witness
          Bitcoin.double_sha256(witness_data)
        end

        def self.witness(features, timestamp, node_id, node_rbg_color, node_alias, addresses)
          new('', features.bytesize, features, timestamp, node_id, node_rbg_color, node_alias, addresses.size, addresses).witness
        end

        def to_json
          to_h.slice(:node_id, :node_rgb_color,:node_alias, :addresses).to_json
        end
      end
    end
  end
end
