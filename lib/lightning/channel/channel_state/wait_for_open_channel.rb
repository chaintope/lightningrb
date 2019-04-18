# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForOpenChannel < ChannelState
        def next(message, data)
          case message
          when OpenChannel
            init_fundee = data[:init_fundee]
            local_param = init_fundee[:local_param]
            remote_init = init_fundee[:remote_init]

            message.validate!

            context.broadcast << ChannelCreated.build(
              channel,
              remote_node_id: context.remote_node_id,
              is_funder: 0,
              temporary_channel_id: message.temporary_channel_id
            )

            minimum_depth = context.node_params.min_depth_blocks
            first_per_commitment_point = ::Lightning::Crypto::Key.per_commitment_point(local_param[:sha_seed], 0)
            accept = AcceptChannel.new(
              temporary_channel_id: message.temporary_channel_id,
              dust_limit_satoshis: local_param[:dust_limit_satoshis],
              max_htlc_value_in_flight_msat: local_param[:max_htlc_value_in_flight_msat],
              channel_reserve_satoshis: local_param[:channel_reserve_satoshis],
              minimum_depth: minimum_depth,
              htlc_minimum_msat: local_param[:htlc_minimum_msat],
              to_self_delay: local_param[:to_self_delay],
              max_accepted_htlcs: local_param[:max_accepted_htlcs],
              funding_pubkey: local_param[:funding_priv_key].pubkey,
              revocation_basepoint: local_param.revocation_basepoint,
              payment_basepoint: local_param.payment_basepoint,
              delayed_payment_basepoint: local_param.delayed_payment_basepoint,
              htlc_basepoint: local_param.htlc_basepoint,
              first_per_commitment_point: first_per_commitment_point
            )
            remote_param = RemoteParam[
              context.remote_node_id,
              message.dust_limit_satoshis,
              message.max_htlc_value_in_flight_msat,
              message.channel_reserve_satoshis,
              message.htlc_minimum_msat,
              message.to_self_delay,
              message.max_accepted_htlcs,
              message.funding_pubkey,
              message.revocation_basepoint,
              message.payment_basepoint,
              message.delayed_payment_basepoint,
              message.htlc_basepoint,
              remote_init.globalfeatures,
              remote_init.localfeatures
            ]
            goto(
              WaitForFundingCreated.new(channel, context),
              data: DataWaitForFundingCreated[
                message.temporary_channel_id,
                local_param,
                remote_param,
                message.funding_satoshis,
                message.push_msat,
                message.feerate_per_kw,
                message.first_per_commitment_point,
                message.channel_flags,
                accept
              ],
              sending: accept
            )
          end
        end
      end
    end
  end
end
