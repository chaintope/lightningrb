# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Syncing < ChannelState
        def next(message, data)
          case message
          when ChannelReestablish
            if data[:buried] == 1
              context.blockchain << WatchConfirmed[channel, data[:commitments][:commit_input].txid.rhex, context.node_params.min_depth_blocks]
            else
              if data[:channel_announcement].is_a? Algebrick::None
                context.forwarder << Lightning::Router::Announcements.make_announcement_signatures(
                  context.node_params ,
                  data[:commitments],
                  data[:short_channel_id]
                )
              end
            end
            channel_update = Lightning::Router::Announcements.make_channel_update(
              context.node_params.chain_hash,
              context.node_params.private_key,
              data[:commitments][:remote_param][:node_id],
              data[:short_channel_id],
              context.node_params.expiry_delta_blocks,
              data[:commitments][:remote_param][:htlc_minimum_msat],
              context.node_params.fee_base_msat,
              context.node_params.fee_proportional_millionths
            )
            goto(Normal.new(channel, context), data: data.copy(channel_update: channel_update))
          end
        end
      end
    end
  end
end
