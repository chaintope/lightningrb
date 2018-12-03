# frozen_string_literal: true

module Lightning
  module Transactions
    module Penalty
      include Lightning::Transactions
      include Lightning::Transactions::Commitment
      def self.make_penalty_tx(
        commit_tx,
        local_dust_limit,
        remote_revocation_pubkey,
        local_final_script_pubkey,
        to_remote_delay,
        remote_delayed_payment_pubkey,
        feerate_per_kw
      )
        fee = Fee.weight2fee(feerate_per_kw, main_penalty_weight)
        redeem_script = Scripts.to_local(
          remote_revocation_pubkey,
          remote_delayed_payment_pubkey,
          to_self_delay: to_remote_delay
        )
        script = Bitcoin::Script.to_p2wsh(redeem_script)
        output_index = find_script_pubkey_index(commit_tx, script)

        amount = commit_tx.outputs[output_index].amount - fee
        raise AmountBelowDustLimit.new if amount < local_dust_limit

        out_point = Bitcoin::OutPoint.new(commit_tx.txid.htb.reverse.bth, output_index)
        input_utxo = Utxo.new(amount, script, commit_tx.txid, output_index, redeem_script)

        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.inputs << Bitcoin::TxIn.new(out_point: out_point, sequence: 0xffffffff)
        tx.outputs << Bitcoin::TxOut.new(value: amount, script_pubkey: local_final_script_pubkey)
        tx.lock_time = 0
        TransactionWithUtxo[tx, input_utxo]
      end
    end
  end
end
