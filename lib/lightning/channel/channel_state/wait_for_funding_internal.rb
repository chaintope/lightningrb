# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingInternal < ChannelState
        def next(message, data)
          match message, (on Funding::MakeFundingTxResponse.(~any, ~any) do |funding_tx, funding_tx_output_index|
            Transactions.inspect(funding_tx)
            local_param = data[:local_param]
            remote_param = data[:remote_param]
            funding_satoshis = data[:funding_satoshis]
            temporary_channel_id = data[:temporary_channel_id]
            remote_first_per_commitment_point = data[:remote_first_per_commitment_point]
            local_spec, local_commit_tx, remote_spec, remote_commit_tx = Commitment.make_first_commitment_txs(
              temporary_channel_id,
              local_param,
              remote_param,
              funding_satoshis,
              data[:push_msat],
              data[:initial_feerate_per_kw],
              funding_tx.txid,
              funding_tx_output_index,
              remote_first_per_commitment_point,
              data[:additional_field]
            )
            Transactions.inspect(remote_commit_tx.tx)
            local_sig_of_remote_tx = Transactions.sign(remote_commit_tx.tx, remote_commit_tx.utxo, local_param.funding_priv_key)
            funding_created = FundingCreated.new(
              temporary_channel_id: temporary_channel_id,
              funding_txid: funding_tx.txid,
              funding_tx_output_index: funding_tx_output_index,
              signature: Lightning::Wire::Signature.new(value: local_sig_of_remote_tx)
            )

            channel_id = Channel.to_channel_id(funding_tx.txid, funding_tx_output_index)
            event = ChannelIdAssigned.build(
              channel,
              remote_node_id: context.remote_node_id,
              temporary_channel_id: temporary_channel_id,
              channel_id: channel_id
            )
            channel.parent << event
            context.broadcast << event
            goto(
              WaitForFundingSigned.new(channel, context),
              data: DataWaitForFundingSigned[
                temporary_channel_id,
                channel_id,
                local_param,
                remote_param,
                funding_tx,
                local_spec,
                local_commit_tx,
                Transactions::Commitment::RemoteCommit[0, remote_spec, remote_commit_tx.tx.txid, remote_first_per_commitment_point],
                data[:last_sent].channel_flags,
                funding_created,
                data[:additional_field]
              ],
              sending: funding_created
            )
          end)
        end
      end
    end
  end
end
