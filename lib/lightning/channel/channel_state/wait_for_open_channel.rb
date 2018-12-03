# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForOpenChannel < ChannelState
        def next(message, data)
          match message, (on ~OpenChannel do |open|
            init_fundee = data[:init_fundee]
            local_param = init_fundee[:local_param]
            remote_init = init_fundee[:remote_init]

            open.validate!

            context.broadcast << ChannelCreated[channel, channel.parent, context.remote_node_id, 0, open.temporary_channel_id]

            minimum_depth = context.node_params.min_depth_blocks
            first_per_commitment_point = ::Lightning::Crypto::Key.per_commitment_point(local_param[:sha_seed], 0)
            accept = AcceptChannel[
              open.temporary_channel_id,
              local_param[:dust_limit_satoshis],
              local_param[:max_htlc_value_in_flight_msat],
              local_param[:channel_reserve_satoshis],
              minimum_depth,
              local_param[:htlc_minimum_msat],
              local_param[:to_self_delay],
              local_param[:max_accepted_htlcs],
              local_param[:funding_priv_key].pubkey,
              local_param.revocation_basepoint,
              local_param.payment_basepoint,
              local_param.delayed_payment_basepoint,
              local_param.htlc_basepoint,
              first_per_commitment_point
            ]
            remote_param = RemoteParam[
              context.remote_node_id,
              open.dust_limit_satoshis,
              open.max_htlc_value_in_flight_msat,
              open.channel_reserve_satoshis,
              open.htlc_minimum_msat,
              open.to_self_delay,
              open.max_accepted_htlcs,
              open.funding_pubkey,
              open.revocation_basepoint,
              open.payment_basepoint,
              open.delayed_payment_basepoint,
              open.htlc_basepoint,
              remote_init.globalfeatures,
              remote_init.localfeatures
            ]
            goto(
              WaitForFundingCreated.new(channel, context),
              data: DataWaitForFundingCreated[
                open.temporary_channel_id,
                local_param,
                remote_param,
                open.funding_satoshis,
                open.push_msat,
                open.feerate_per_kw,
                open.first_per_commitment_point,
                open.channel_flags,
                accept
              ],
              sending: accept
            )
          end)
        end
      end
    end
  end
end
