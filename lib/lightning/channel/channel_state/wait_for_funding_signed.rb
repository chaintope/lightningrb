# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingSigned < ChannelState
        def next(message, data)
          case message
          when FundingSigned
            temporary_channel_id = data[:temporary_channel_id]
            channel_id = data[:channel_id]
            local_param = data[:local_param]
            remote_param = data[:remote_param]
            funding_tx = data[:funding_tx]
            local_spec = data[:local_spec]
            local_commit_tx = data[:local_commit_tx]
            remote_commit = data[:remote_commit]
            channel_flags = data[:channel_flags]
            funding_created = data[:last_sent]

            local_sig_of_local_tx = Transactions.sign(local_commit_tx.tx, local_commit_tx.utxo, local_param.funding_priv_key)
            signed_local_commit_tx = Transactions.add_sigs(
              local_commit_tx.tx,
              local_commit_tx.utxo,
              local_param.funding_priv_key.pubkey,
              remote_param.funding_pubkey,
              local_sig_of_local_tx,
              message.signature.value
            )
            unless Transactions.spendable?(signed_local_commit_tx)
              # TODO
              return
            end

            commit_utxo = local_commit_tx.utxo
            random_key = Bitcoin::Key.new(priv_key: SecureRandom.hex(32))

            commitments = Commitments[
              local_param,
              remote_param,
              channel_flags,
              LocalCommit[0, local_spec, PublishableTxs[TransactionWithUtxo[signed_local_commit_tx, commit_utxo], []]],
              remote_commit,
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

            next_data = store(DataWaitForFundingConfirmed[temporary_channel_id, commitments, ::Algebrick::None, funding_created])

            context.blockchain << WatchUtxoSpent[channel, commit_utxo.txid.rhex, commit_utxo.index]
            context.blockchain << WatchConfirmed[channel, commit_utxo.txid.rhex, context.node_params.min_depth_blocks]

            context.wallet.commit(funding_tx)
            context.broadcast << ChannelSignatureReceived[channel, commitments]

            log(Logger::INFO, :channel, "funding_tx is broadcasted. #{funding_tx.txid}:#{funding_tx.to_payload.bth}")
            log(Logger::INFO, :channel, "================================================================================")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "Wait For Funding Confirmed")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "================================================================================")

            goto(
              WaitForFundingConfirmed.new(channel, context),
              data: next_data
            )
          end
        end
      end
    end
  end
end
