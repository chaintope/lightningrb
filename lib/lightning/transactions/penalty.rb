# frozen_string_literal: true

module Lightning
  module Transactions
    module Penalty
      include Lightning::Exceptions
      include Lightning::Transactions
      include Lightning::Transactions::Commitment

      def self.make_to_local_penalty_tx(
        commit_tx,
        local_dust_limit,
        remote_revocation_pubkey,
        local_final_script_pubkey,
        to_remote_delay,
        remote_delayed_payment_pubkey,
        feerate_per_kw
      )
        make_penalty_tx(
          commit_tx,
          local_dust_limit,
          remote_revocation_pubkey,
          local_final_script_pubkey,
          to_remote_delay,
          remote_delayed_payment_pubkey,
          feerate_per_kw,
          to_local_penalty_weight
        )
      end

      def self.make_offered_htlc_penalty_tx(
        commit_tx,
        local_dust_limit,
        remote_revocation_pubkey,
        local_final_script_pubkey,
        to_remote_delay,
        remote_delayed_payment_pubkey,
        feerate_per_kw
      )
        make_penalty_tx(
          commit_tx,
          local_dust_limit,
          remote_revocation_pubkey,
          local_final_script_pubkey,
          to_remote_delay,
          remote_delayed_payment_pubkey,
          feerate_per_kw,
          offered_htlc_weight
        )
      end

      def self.make_accepted_htlc_penalty_tx(
        commit_tx,
        local_dust_limit,
        remote_revocation_pubkey,
        local_final_script_pubkey,
        to_remote_delay,
        remote_delayed_payment_pubkey,
        feerate_per_kw
      )
        make_penalty_tx(
          commit_tx,
          local_dust_limit,
          remote_revocation_pubkey,
          local_final_script_pubkey,
          to_remote_delay,
          remote_delayed_payment_pubkey,
          feerate_per_kw,
          accepted_htlc_penalty_weight
        )
      end

      def self.make_penalty_tx(
        commit_tx,
        local_dust_limit,
        remote_revocation_pubkey,
        local_final_script_pubkey,
        to_remote_delay,
        remote_delayed_payment_pubkey,
        feerate_per_kw,
        weight
      )
        fee = Fee.weight2fee(feerate_per_kw, weight)
        redeem_script = Scripts.to_local(
          remote_revocation_pubkey,
          remote_delayed_payment_pubkey,
          to_self_delay: to_remote_delay
        )
        script = Bitcoin::Script.to_p2wsh(redeem_script)
        output_index = Commitment.find_script_pubkey_index(commit_tx, script)

        amount = commit_tx.outputs[output_index].value - fee
        raise AmountBelowDustLimit.new if amount < local_dust_limit

        out_point = Bitcoin::OutPoint.new(commit_tx.txid.htb.reverse.bth, output_index)
        input_utxo = Utxo.new(amount, script, commit_tx.txid, output_index, redeem_script)

        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.inputs << Bitcoin::TxIn.new(out_point: out_point, sequence: 0xffffffff)
        script_pubkey = Bitcoin::Script.parse_from_payload(local_final_script_pubkey.htb)
        tx.outputs << Bitcoin::TxOut.new(value: amount, script_pubkey: script_pubkey)
        tx.lock_time = 0
        TransactionWithUtxo[tx, input_utxo]
      end

      def self.to_local_penalty_weight
        # - version: 4 bytes
        # - count_tx_in: 1 byte
        # - tx_in:
        #   - previous_out_point: 36 bytes
        #     - hash: 32 bytes
        #     - index: 4 bytes
        #   - var_int: 1 byte (script_sig length)
        #   - script_sig: 0 bytes
        #   - to_local_penalty_witness: 160 bytes
        #     - number_of_witness_elements: 1 byte
        #     - revocation_sig_length: 1 byte
        #     - revocation_sig: 73 bytes
        #     - one_length: 1 byte
        #     - witness_script_length: 1 byte
        #     - witness_script (to_local_script): 83 bytes
        #       - OP_IF: 1 byte
        #         - OP_DATA: 1 byte (revocationpubkey length)
        #         - revocationpubkey: 33 bytes
        #       - OP_ELSE: 1 byte
        #         - OP_DATA: 1 byte (delay length)
        #         - delay: 8 bytes
        #         - OP_CHECKSEQUENCEVERIFY: 1 byte
        #         - OP_DROP: 1 byte
        #         - OP_DATA: 1 byte (local_delayedpubkey length)
        #         - local_delayedpubkey: 33 bytes
        #       - OP_ENDIF: 1 byte
        #       - OP_CHECKSIG: 1 byte
        #   - sequence: 4 bytes
        # count_tx_out: 1 byte
        # tx_out: 31 bytes
        #   - output
        #     - value: 8 bytes
        #     - var_int: 1 byte (pk_script length)
        #     - pk_script (p2wpkh): 22 bytes
        #       - OP_0: 1 byte
        #       - OP_DATA: 1 byte (public_key_HASH160 length)
        #       - public_key_HASH160: 20 bytes
        # lock_time: 4 bytes
        488
      end

      def self.offered_htlc_penalty_weight
        # offered_htlc_script: 133 bytes
        #
        # offered_htlc_penalty_witness: 243 bytes
        #     - number_of_witness_elements: 1 byte
        #     - revocation_sig_length: 1 byte
        #     - revocation_sig: 73 bytes
        #     - revocation_key_length: 1 byte
        #     - revocation_key: 33 bytes
        #     - witness_script_length: 1 byte
        #     - witness_script (offered_htlc_script)
        571
      end

      def self.accepted_htlc_penalty_weight
        # accepted_htlc_script: 139 bytes
        #
        # accepted_htlc_penalty_witness: 249 bytes
        #     - number_of_witness_elements: 1 byte
        #     - revocation_sig_length: 1 byte
        #     - revocation_sig: 73 bytes
        #     - revocationpubkey_length: 1 byte
        #     - revocationpubkey: 33 bytes
        #     - witness_script_length: 1 byte
        #     - witness_script (accepted_htlc_script)
        577
      end
    end
  end
end
