# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingConfirmed < ChannelState
        def next(message, data)
          match message, (on ~FundingLocked do |msg|
            task = Concurrent::TimerTask.new(execution_interval: 5) do
              channel.reference << msg
              task.shutdown
            end
            task.execute
            [self, data]
          end), (on WatchEventConfirmed.(~any, ~any, ~any) do |event_type, block_height, tx_index|
            return [self, data] unless event_type == 'confirmed'
            commitments = data[:commitments]
            next_per_commitment_point = Lightning::Crypto::Key.per_commitment_point(commitments[:local_param].sha_seed, 1)
            funding_locked = FundingLocked[
              commitments[:channel_id],
              next_per_commitment_point
            ]
            short_channel_id = Channel.to_short_id(block_height, tx_index, commitments[:commit_input].out_point.index)
            goto(
              WaitForFundingLocked.new(channel, context),
              data: store(DataWaitForFundingLocked[
                commitments, short_channel_id, funding_locked
              ]),
              sending: funding_locked
            )
          end)
        end
      end
    end
  end
end
