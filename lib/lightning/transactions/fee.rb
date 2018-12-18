module Lightning
  module Transactions
    module Fee
      COMMIT_WEIGHT = 724
      HTLC_TIMEOUT_WEIGHT = 663
      HTLC_SUCCESS_WEIGHT = 703
      CLAIM_P2_WPKHOUTPUT_WEIGHT = 437
      CLAIM_HTLC_DELAYED_WEIGHT = 482
      CLAIM_HTLC_SUCCESS_WEIGHT = 570
      CLAIM_HTLC_TIMEOUT_WEIGHT = 544
      MAIN_PENALTY_WEIGHT = 483

      def self.weight2fee(feerate_per_kw, weight)
        (feerate_per_kw * weight) / 1000
      end

      def self.commit_tx_fee(dust_limit, spec)
        trimmed_offered_htlcs = trim_offered_htlcs(dust_limit, spec)
        trimmed_received_htlcs = trim_received_htlcs(dust_limit, spec)
        weight = COMMIT_WEIGHT + 172 * (trimmed_offered_htlcs.size + trimmed_received_htlcs.size)
        weight2fee(spec.feerate_per_kw, weight)
      end

      def self.trim_offered_htlcs(dust_limit, spec)
        htlc_timeout_fee = weight2fee(spec.feerate_per_kw, HTLC_TIMEOUT_WEIGHT)
        spec.offered.
          select { |htlc| htlc.add.amount_msat / 1000 >= (dust_limit + htlc_timeout_fee) }
      end

      def self.trim_received_htlcs(dust_limit, spec)
        htlc_success_fee = weight2fee(spec.feerate_per_kw, HTLC_SUCCESS_WEIGHT)
        spec.received.
          select { |htlc| htlc.add.amount_msat / 1000 >= (dust_limit + htlc_success_fee) }
      end

      def self.first_closing_fee(commitments, local_script_pubkey, remote_script_pubkey)
        dummy_closing_tx = Closing.make_closing_tx(commitments, local_script_pubkey, remote_script_pubkey, 0)
        tx = dummy_closing_tx.tx
        script_witness = Bitcoin::ScriptWitness.new
        script_witness.stack << ''
        script_witness.stack << 'aa' * 71
        script_witness.stack << 'bb' * 71
        tx.inputs.first.script_witness = script_witness
        weight = tx.weight
        feerate_per_kw = commitments[:local_commit][:spec][:feerate_per_kw]
        weight2fee(feerate_per_kw, weight)
      end
    end
  end
end
