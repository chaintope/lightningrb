# frozen_string_literal: true

module Lightning
  class NodeParams
    attr_accessor :node_id,
                  :ping_interval,
                  :private_key,
                  :extended_private_key,
                  :dust_limit_satoshis,
                  :max_htlc_value_in_flight_msat,
                  :reserve_to_funding_ratio,
                  :htlc_minimum_msat,
                  :delay_blocks,
                  :max_accepted_htlcs,
                  :globalfeatures,
                  :localfeatures,
                  :feerates_per_kw,
                  :chain_hash,
                  :min_depth_blocks,
                  :fee_base_msat,
                  :fee_proportional_millionths,
                  :expiry_delta_blocks,
                  :maximum_feerate_per_kw,
                  :minimum_feerate_per_kw
    def initialize
      seed =
        if File.exist?('seed.dat')
          File.read('seed.dat')
        else
          SecureRandom.hex(32).tap { |id| File.write('seed.dat', id) }
        end
      master = Bitcoin::ExtKey.generate_master(seed)
      @node_id = master.ext_pubkey.pubkey
      @ping_interval = 0
      @private_key = master.key.priv_key
      @extended_private_key = master
      @dust_limit_satoshis = 546
      @max_htlc_value_in_flight_msat = 100_000
      @reserve_to_funding_ratio = 0.01
      @htlc_minimum_msat = 0
      @delay_blocks = 144
      @max_accepted_htlcs = 10
      @globalfeatures = "00"
      @localfeatures = "80"
      @feerates_per_kw = 46_080
      @chain_hash = '06226e46111a0b59caaf126043eb5bbf28c34f3a5e332a1fc7b2b73cf188910f'
      @min_depth_blocks = 1
      @fee_base_msat = 1000
      @fee_proportional_millionths = 100
      @expiry_delta_blocks = 144
      @maximum_feerate_per_kw = 100_000_000
      @minimum_feerate_per_kw = 253
    end
  end
end
