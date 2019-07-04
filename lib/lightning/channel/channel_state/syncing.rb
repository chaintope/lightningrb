# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class Syncing < ChannelState
        def next(message, data)
          case message
          when ChannelReestablish
            unless data.open?
              commit_utxo = data[:commitments][:commit_input]
              context.blockchain << WatchConfirmed[channel, commit_utxo.txid.rhex, context.node_params.min_depth_blocks]
            end

            case data
            when DataWaitForFundingConfirmed
              goto(WaitForFundingConfirmed.new(channel, context), data: data)
            when DataWaitForFundingLocked
              commitments = data[:commitments]
              temporary_channel_id = data[:temporary_channel_id]
              short_channel_id = data[:short_channel_id]
              next_per_commitment_point = Lightning::Crypto::Key.per_commitment_point(commitments[:local_param].sha_seed, 1)
              funding_locked = FundingLocked.new(
                channel_id: commitments[:channel_id],
                next_per_commitment_point: next_per_commitment_point
              )
              goto(
                WaitForFundingLocked.new(channel, context),
                data: store(DataWaitForFundingLocked[
                  temporary_channel_id, commitments, short_channel_id, funding_locked, data[:additional_field]
                ]),
                sending: funding_locked
              )
            when DataNormal
              if data.open? && data[:channel_announcement].is_a?(Algebrick::None)
                context.forwarder << Lightning::Router::Announcements.make_announcement_signatures(
                  context.node_params, data[:commitments], data[:short_channel_id]
                )
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
end
