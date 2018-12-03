# frozen_string_literal: true

module Lightning
  module Transactions
    include Algebrick

    HtlcSuccess = Algebrick.type do
      fields! tx: Bitcoin::Tx,
              utxo: Lightning::Transactions::Utxo
    end

    module HtlcSuccess
      include Lightning::Channel::Messages
      include Lightning::Transactions
      include Lightning::Channel::Messages::TransactionWithUtxo

      def self.make_htlc_success_tx(
        commit_tx,
        local_dust_limit,
        local_revocation_pubkey,
        to_local_delay,
        local_delayed_payment_pubkey,
        local_htlc_pubkey,
        remote_htlc_pubkey,
        feerate_per_kw,
        htlc
      )
        fee = Fee.weight2fee(feerate_per_kw, Fee::HTLC_SUCCESS_WEIGHT)
        amount = htlc.amount_msat / 1000 - fee
        raise AmountBelowDustLimit.new if amount < local_dust_limit

        redeem_script = Scripts.received_htlc(
          local_revocation_pubkey,
          local_htlc_pubkey,
          remote_htlc_pubkey,
          htlc.payment_hash,
          htlc.cltv_expiry
        )
        script = Bitcoin::Script.to_p2wsh(redeem_script)
        output_index = Commitment.find_script_pubkey_index(commit_tx, script)

        out_point = Bitcoin::OutPoint.new(commit_tx.txid.htb.reverse.bth, output_index)
        input_utxo = Utxo.new(htlc.amount_msat / 1000, script, commit_tx.txid, output_index, redeem_script)
        to_local_script = Scripts.to_local(
          local_revocation_pubkey,
          local_delayed_payment_pubkey,
          to_self_delay: to_local_delay
        )
        to_local_output = Bitcoin::TxOut.new(value: amount, script_pubkey: Bitcoin::Script.to_p2wsh(to_local_script))

        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.inputs << Bitcoin::TxIn.new(out_point: out_point, sequence: 0)
        tx.outputs << to_local_output
        tx.lock_time = 0
        HtlcSuccess[tx, input_utxo]
      end

      def witness(local_sig, remote_sig, payment_preimage, offered_htlc_script)
        witness = Bitcoin::ScriptWitness.new
        witness.stack << ''
        Bitcoin::Multisig.add_sig_to_multisig_script_witness(remote_sig.htb, witness)
        Bitcoin::Multisig.add_sig_to_multisig_script_witness(local_sig.htb, witness)
        witness.stack << payment_preimage.htb
        witness.stack << offered_htlc_script.to_payload
        witness
      end

      def add_sigs(local_sig, remote_sig, payment_preimage)
        offered_htlc_script = utxo.redeem_script
        tx.inputs.first.script_witness = witness(local_sig, remote_sig, payment_preimage, offered_htlc_script)
      end
    end
  end
end
