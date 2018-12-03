# frozen_string_literal: true

module Lightning
  module Channel
    class ChannelState
      class WaitForInitInterval < ChannelState
        def next(message, data)
          match message, (on ~InputInitFunder do |init|
            context.broadcast << ChannelCreated[channel, channel.parent, context.remote_node_id, 1, init[:temporary_channel_id]]
            context.forwarder << init[:remote]
            local_param = init[:local_param]
            first_per_commitment_point = Lightning::Crypto::Key.per_commitment_point(local_param[:sha_seed], 0)
            open = OpenChannel[
              context.node_params.chain_hash,
              init[:temporary_channel_id],
              init[:funding_satoshis],
              init[:push_msat],
              local_param[:dust_limit_satoshis],
              local_param[:max_htlc_value_in_flight_msat],
              local_param[:channel_reserve_satoshis],
              local_param[:htlc_minimum_msat],
              init[:initial_feerate_per_kw],
              local_param[:to_self_delay],
              local_param[:max_accepted_htlcs],
              local_param[:funding_priv_key].pubkey,
              local_param.revocation_basepoint,
              local_param.payment_basepoint,
              local_param.delayed_payment_basepoint,
              local_param.htlc_basepoint,
              first_per_commitment_point,
              init[:channel_flags]
            ]
            open.validate!
            goto(
              WaitForAcceptChannel.new(channel, context),
              data: DataWaitForAcceptChannel[init, open],
              sending: open
            )
          end), (on ~InputInitFundee do |init|
            return [self, data] if init[:local_param].funder == 1
            context.forwarder << init[:remote]
            goto(
              WaitForOpenChannel.new(channel, context),
              data: DataWaitForOpenChannel[init]
            )
          end), (on ~OpenChannel do |msg|
            # TODO: pending open_channel message.
            [self, data]
          end)

        rescue => e
          log(Logger::ERROR, :channel, e.message)
          [self, data]
        end
      end
    end
  end
end
