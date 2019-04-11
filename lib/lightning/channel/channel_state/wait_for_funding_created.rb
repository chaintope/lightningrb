# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingCreated < ChannelState
        def next(message, data)
          case message
          when FundingCreated
            local_param = data[:local_param]
            remote_param = data[:remote_param]
            funding_satoshis = data[:funding_satoshis]
            temporary_channel_id = data[:temporary_channel_id]
            push_msat = data[:push_msat]
            initial_feerate_per_kw = data[:initial_feerate_per_kw]
            remote_first_per_commitment_point = data[:remote_first_per_commitment_point]
            channel_flags = data[:channel_flags]
            funding_tx_txid = message.funding_txid
            funding_tx_output_index = message.funding_output_index
            remote_sig = message.signature

            message.validate!(temporary_channel_id)

            local_spec, local_commit_tx, remote_spec, remote_commit_tx = Transactions::Commitment.make_first_commitment_txs(
              temporary_channel_id,
              local_param,
              remote_param,
              funding_satoshis,
              push_msat,
              initial_feerate_per_kw,
              funding_tx_txid,
              funding_tx_output_index,
              remote_first_per_commitment_point,
              # node_params.max_feerate_mismatch
            )
            Transactions.inspect(local_commit_tx.tx)
            local_sig_of_local_tx = Transactions.sign(local_commit_tx.tx, local_commit_tx.utxo, local_param.funding_priv_key)
            signed_local_commit_tx = Transactions.add_sigs(
              local_commit_tx.tx,
              local_commit_tx.utxo,
              local_param.funding_priv_key.pubkey,
              remote_param.funding_pubkey,
              local_sig_of_local_tx,
              remote_sig.value
            )
            unless Transactions.spendable?(signed_local_commit_tx)
              # TODO
              return
            end

            local_sig_of_remote_tx = Transactions.sign(remote_commit_tx.tx, remote_commit_tx.utxo, local_param.funding_priv_key)
            channel_id = Channel.to_channel_id(funding_tx_txid, funding_tx_output_index)
            event = ChannelIdAssigned.build(
              channel,
              remote_node_id: context.remote_node_id,
              temporary_channel_id: temporary_channel_id,
              channel_id: channel_id
            )
            channel.parent << event
            context.broadcast << event

            log(Logger::INFO, :channel, "local_sig_of_remote_tx:#{local_sig_of_remote_tx}")

            commit_utxo = local_commit_tx.utxo
            funding_signed = FundingSigned.new(
              channel_id: channel_id,
              signature: Lightning::Wire::Signature.new(value: local_sig_of_remote_tx)
            )
            random_key = Bitcoin::Key.generate

            # TODO Watch UTXO to detect it to be spent

            context.blockchain << WatchConfirmed[channel, commit_utxo.txid.rhex, context.node_params.min_depth_blocks]

            commitments = Commitments[
              local_param,
              remote_param,
              channel_flags,
              LocalCommit[0, local_spec, PublishableTxs[TransactionWithUtxo[signed_local_commit_tx, commit_utxo], []]],
              RemoteCommit[0, remote_spec, remote_commit_tx.tx.txid, remote_first_per_commitment_point],
              LocalChanges[[], [], []],
              RemoteChanges[[], [], []],
              0,
              0,
              {},
              random_key.pubkey,
              commit_utxo,
              {},
              channel_id
            ]
            context.broadcast << ChannelSignatureReceived.build(channel)

            log(Logger::INFO, :channel, "================================================================================")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "Wait For Funding Confirmed")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "================================================================================")
            goto(
              WaitForFundingConfirmed.new(channel, context),
              data: store(DataWaitForFundingConfirmed[
                temporary_channel_id,
                commitments,
                ::Algebrick::None,
                funding_signed
              ]),
              sending: funding_signed
            )
          end
        end
      end
    end
  end
end
