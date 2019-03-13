# frozen_string_literal: true

module Lightning
  class Feature
    # Requires or supports extra channel_reestablish fields
    OPTION_DATA_LOSS_PROTECT_COMPULSORY = 0
    OPTION_DATA_LOSS_PROTECT_OPTIONAL = 1

    # Indicates that the sending node needs a complete routing information dump
    # INITIAL_ROUTING_SYNC_BIT_COMPULSORY = 2
    INITIAL_ROUTING_SYNC_BIT_OPTIONAL = 3

    # Commits to a shutdown scriptpubkey when opening channel
    OPTION_UPFRONT_SHUTDOWN_SCRIPT_COMPULSORY = 4
    OPTION_UPFRONT_SHUTDOWN_SCRIPT_OPTIONAL = 5

    # More sophisticated gossip control
    GOSSIP_QUERY_COMPULSORY = 6
    GOSSIP_QUERY_OPTIONAL = 7

    def initialize(flags_hex_string)
      @flags = flags_hex_string.to_i(16)
    end

    def option_data_loss_protect?
      has_feature?(OPTION_DATA_LOSS_PROTECT_COMPULSORY) ||
      has_feature?(OPTION_DATA_LOSS_PROTECT_OPTIONAL)
    end

    def initial_routing_sync?
      has_feature?(INITIAL_ROUTING_SYNC_BIT_OPTIONAL)
    end

    def option_upfront_shutdown_script?
      has_feature?(OPTION_UPFRONT_SHUTDOWN_SCRIPT_COMPULSORY) ||
      has_feature?(OPTION_UPFRONT_SHUTDOWN_SCRIPT_OPTIONAL)
    end

    def gossip_queries?
      has_feature?(GOSSIP_QUERY_COMPULSORY) ||
      has_feature?(GOSSIP_QUERY_OPTIONAL)
    end

    def valid?
      mask = (1 << OPTION_DATA_LOSS_PROTECT_COMPULSORY) +
        (1 << OPTION_UPFRONT_SHUTDOWN_SCRIPT_COMPULSORY) +
        (1 << GOSSIP_QUERY_COMPULSORY)

      flags = @flags & ~mask
      while flags > 0
        return false if flags & 1 == 1
        flags = flags >> 2
      end
      true
    end

    private

    def has_feature?(feature_bit)
      @flags & (1 << feature_bit) != 0
    end
  end
end
