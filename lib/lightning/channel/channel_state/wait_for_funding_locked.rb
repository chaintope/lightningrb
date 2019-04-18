# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForFundingLocked < ChannelState
        def next(message, data)
          case message
          when FundingLocked
            next_per_commitment_point = message.next_per_commitment_point
            commitments = data[:commitments]
            temporary_channel_id = data[:temporary_channel_id]
            short_channel_id = data[:short_channel_id]
            channel_update = Lightning::Router::Announcements.make_channel_update(
              context.node_params.chain_hash,
              context.node_params.private_key,
              context.remote_node_id,
              short_channel_id,
              context.node_params.expiry_delta_blocks,
              commitments[:remote_param][:htlc_minimum_msat],
              context.node_params.fee_base_msat,
              context.node_params.fee_proportional_millionths
            )
            context.broadcast << ShortChannelIdAssigned.build(
              channel,
              channel_id: commitments[:channel_id],
              short_channel_id: short_channel_id
            )

            new_commitments = Commitments[
              commitments[:local_param],
              commitments[:remote_param],
              commitments[:channel_flags],
              commitments[:local_commit],
              commitments[:remote_commit],
              commitments[:local_changes],
              commitments[:remote_changes],
              commitments[:local_next_htlc_id],
              commitments[:remote_next_htlc_id],
              commitments[:origin_channels],
              next_per_commitment_point,
              commitments[:commit_input],
              commitments[:remote_per_commitment_secrets],
              commitments[:channel_id],
            ]
            log(Logger::INFO, :channel, "================================================================================")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "Chanel State is Normal")
            log(Logger::INFO, :channel, "")
            log(Logger::INFO, :channel, "================================================================================")

            goto(
              Normal.new(channel, context),
              data: store(DataNormal[temporary_channel_id, new_commitments, short_channel_id, 0, None, channel_update, None, None])
            )
          when WatchEventConfirmed
            task = Concurrent::TimerTask.new(execution_interval: 60) do
              channel.reference << message
              task.shutdown
            end
            task.execute
            [self, data]
          end
        end
      end
    end
  end
end
