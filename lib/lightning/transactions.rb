# frozen_string_literal: true

module Lightning
  module Transactions
    autoload :Closing, 'lightning/transactions/closing'
    autoload :CommitmentSpec, 'lightning/transactions/commitment_spec'
    autoload :Commitment, 'lightning/transactions/commitment'
    autoload :DirectedHtlc, 'lightning/transactions/directed_htlc'
    autoload :Fee, 'lightning/transactions/fee'
    autoload :Funding, 'lightning/transactions/funding'
    autoload :HtlcSuccess, 'lightning/transactions/htlc_success'
    autoload :HtlcTimeout, 'lightning/transactions/htlc_timeout'
    autoload :Scripts, 'lightning/transactions/scripts'
    autoload :Utxo, 'lightning/transactions/utxo'

    class InvalidTransactionError < StandardError
    end

    def self.inspect(tx)
      puts "----inspect tx----"
      puts "txid=#{tx.txid}"
      puts "version=#{tx.version}"
      puts "lock_time=#{tx.lock_time}"
      tx.inputs.each.with_index do |input, i|
        puts "input[#{i}]=#{input.out_point.hash.rhex}/#{input.out_point.index}/#{input.sequence}"
      end
      tx.outputs.each.with_index do |output, i|
        puts "output[#{i}]=#{output.value}/#{output.script_pubkey.to_payload.bth}"
      end
    end

    def self.sign(tx, input_utxo, key)
      raise InvalidTransactionError unless tx.inputs.size == 1
      index = 0
      amount = input_utxo.value
      redeem_script = input_utxo.redeem_script
      sighash = tx.sighash_for_input(index, redeem_script, amount: amount, sig_version: :witness_v0)
      key.sign(sighash).bth
    end

    def self.add_sigs(
      tx,
      input_utxo,
      local_funding_pubkey,
      remote_funding_pubkey,
      local_sig_of_local_tx,
      remote_sig
    )
      raise InvalidTransactionError unless tx.inputs.size == 1
      index = 0
      amount = input_utxo.value
      redeem_script = input_utxo.redeem_script
      sighash = tx.sighash_for_input(index, redeem_script, amount: amount, sig_version: :witness_v0)
      script_witness = Bitcoin::ScriptWitness.new
      script_witness.stack << ''
      Bitcoin::Multisig.add_sig_to_multisig_script_witness(
        local_sig_of_local_tx.htb, script_witness
      )
      Bitcoin::Multisig.add_sig_to_multisig_script_witness(remote_sig.htb, script_witness)
      script_witness.stack << redeem_script.to_payload
      tx.inputs.first.script_witness = script_witness
      Bitcoin::Multisig.sort_witness_multisig_signatures(script_witness, sighash)
      tx.inputs.first.script_witness = script_witness
      tx
    end

    def self.spendable?(tx)
      true
    end

    def self.check_sig(htlc_tx, remote_sig, remote_htlc_pubkey)
      amount = htlc_tx.utxo.value
      redeem_script = htlc_tx.utxo.redeem_script
      htlc_tx.tx.verify_input_sig(0, Bitcoin::Script.to_p2wsh(redeem_script), amount: amount)
    end
  end
end
