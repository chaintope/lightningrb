# frozen_string_literal: true

module Lightning
  module Transactions
    class Closing
      include Lightning::Exceptions

      attr_accessor :tx, :closing_signed

      # 03-transactions.md#closing-transaction
      # version: 2
      # locktime: 0
      # txin count: 1
      # txin[0] outpoint: txid and output_index from funding_created message
      # txin[0] sequence: 0xFFFFFFFF
      # txin[0] script bytes: 0
      # txin[0] witness: 0 <signature_for_pubkey1> <signature_for_pubkey2>
      # txout count: 0, 1 or 2
      # txout amount: final balance to be paid to one node (minus fee_satoshis from closing_signed, if this peer funded the channel)
      # txout script: as specified in that node's scriptpubkey in its shutdown message
      def self.make_closing_tx(commitments, local_script_pubkey, remote_script_pubkey, closing_fee)
        dust_limit_satoshis = [
          commitments[:local_param].dust_limit_satoshis,
          commitments[:remote_param].dust_limit_satoshis,
        ].max
        local_commit = commitments[:local_commit]

        to_local_amount, to_remote_amount =
          if commitments[:local_param].funder == 1
            [local_commit.spec.to_local_msat / 1000 - closing_fee, local_commit.spec.to_remote_msat / 1000]
          else
            [local_commit.spec.to_local_msat / 1000, local_commit.spec.to_remote_msat / 1000 - closing_fee]
          end

        to_local_output =
          if to_local_amount >= dust_limit_satoshis && local_script_pubkey
            Bitcoin::TxOut.new(value: to_local_amount, script_pubkey: local_script_pubkey)
          end
        to_remote_output =
          if to_remote_amount >= dust_limit_satoshis
            Bitcoin::TxOut.new(value: to_remote_amount, script_pubkey: remote_script_pubkey)
          end

        tx = Bitcoin::Tx.new
        tx.version = 2
        tx.inputs << Bitcoin::TxIn.new(out_point: commitments[:commit_input].out_point)
        tx.outputs << to_local_output if to_local_output
        tx.outputs << to_remote_output if to_remote_output
        tx.lock_time = 0
        Lightning::Utils::LexicographicalOrdering.sort(tx)
        local_closing_sig = Transactions.sign(
          tx, commitments[:commit_input], commitments[:local_param].funding_priv_key
        )
        closing_signed = Lightning::Wire::LightningMessages::ClosingSigned[
          commitments[:channel_id], closing_fee, local_closing_sig
        ]
        new(tx, closing_signed)
      end

      def self.make_first_closing_tx(commitments, local_script_pubkey, remote_script_pubkey)
        fee = Fee.first_closing_fee(commitments, local_script_pubkey, remote_script_pubkey)
        make_closing_tx(commitments, local_script_pubkey, remote_script_pubkey, fee)
      end

      def self.valid_signature?(
        commitments,
        local_script_pubkey,
        remote_script_pubkey,
        remote_closing_fee,
        remote_closing_signature
      )
        last_commit_fee_satoshi =
          commitments[:commit_input].value -
          commitments[:local_commit].publishable_txs.commit_tx.tx.outputs.sum(&:value)
        raise InvalidCloseFee.new(remote_closing_fee) if remote_closing_fee > last_commit_fee_satoshi

        closing = make_closing_tx(
          commitments,
          local_script_pubkey,
          remote_script_pubkey,
          remote_closing_fee
        )
        signed_closing_tx = Transactions.add_sigs(
          closing.tx, commitments[:commit_input],
          commitments[:local_param].funding_priv_key.pubkey,
          commitments[:remote_param].funding_pubkey,
          closing.closing_signed.signature,
          remote_closing_signature
        )
        Transactions.spendable?(signed_closing_tx)
        signed_closing_tx
      end

      # @param String script_pubkey is lock script for destination. hex string.
      def self.valid_final_script_pubkey?(script_pubkey)
        script = Bitcoin::Script.parse_from_payload(script_pubkey.htb)
        [script.p2pkh?, script.p2sh?, script.p2wpkh?, script.p2wsh?].any?
      end

      def self.next_closing_fee(local_closing_fee, remote_closing_fee)
        (local_closing_fee + remote_closing_fee) / 2
      end

      private

      def initialize(tx, closing_signed)
        @tx = tx
        @closing_signed = closing_signed
      end
    end
  end
end
