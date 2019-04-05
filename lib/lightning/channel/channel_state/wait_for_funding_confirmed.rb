# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingConfirmed < ChannelState
        def next(message, data)
          case message
          when FundingLocked
            task = Concurrent::TimerTask.new(execution_interval: 5) do
              channel.reference << message
              task.shutdown
            end
            task.execute
            [self, data]
          when WatchEventConfirmed
            event_type = message[:event_type]
            block_height = message[:block_height]
            tx_index = message[:tx_index]
            return [self, data] unless event_type == 'confirmed'
            commitments = data[:commitments]
            next_per_commitment_point = Lightning::Crypto::Key.per_commitment_point(commitments[:local_param].sha_seed, 1)
            funding_locked = FundingLocked.new(
              channel_id: commitments[:channel_id],
              next_per_commitment_point: next_per_commitment_point
            )
            temporary_channel_id = data[:temporary_channel_id]
            short_channel_id = Channel.to_short_id(block_height, tx_index, commitments[:commit_input].out_point.index)
            goto(
              WaitForFundingLocked.new(channel, context),
              data: store(DataWaitForFundingLocked[
                temporary_channel_id, commitments, short_channel_id, funding_locked
              ]),
              sending: funding_locked
            )
          when WatchUtxoSpent
            handle_utxo_spent(message, data)
            [self, data]
          end
        end

        def handle_utxo_spent(message, data)
          out_point = data[:commitments][:commit_input].out_point
          if (out_point.hash == message[:out_point].tx_hash && out_point.index == message[:out_point].index)

          end
        end
      end
    end
  end
end
