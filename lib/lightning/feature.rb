# frozen_string_literal: true

module Lightning
  module Feature
    INITIAL_ROUTING_SYNC_BIT_MANDATORY = 2
    INITIAL_ROUTING_SYNC_BIT_OPTIONAL = 3
    def self.initial_routing_sync?(features)
      features.to_i[INITIAL_ROUTING_SYNC_BIT_OPTIONAL] == 1
    end

    def self.supported?(features)
      bits = features.htb.unpack('b*').first
      bits.size.times do |i|
        return false if required_bit?(bits, i)
      end
      true
    end

    def self.required_bit?(bits, i)
      i.even? && bits[i] == '1'
    end
  end
end
