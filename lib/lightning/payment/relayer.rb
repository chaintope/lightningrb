# frozen_string_literal: true

module Lightning
  module Payment
    class Relayer < Concurrent::Actor::Context
      include Lightning::Channel
      include Lightning::Channel::Messages
      include Lightning::Channel::Events
      include Lightning::Onion
      include Lightning::Onion::FailureMessages
      include Lightning::Payment::Events
      include Lightning::Wire::LightningMessages
      include Algebrick::Matching

      Local = Algebrick.atom

      Relayed = Algebrick.type do
        fields! original_channel_id: String,
                original_htlc_id: Numeric,
                amount_msat_in: Numeric,
                amount_msat_out: Numeric
      end

      Origin = Algebrick.type do
        variants Local, Relayed
      end

      ForwardAdd = Algebrick.type do
        fields! add: UpdateAddHtlc
      end
      ForwardFulfill = Algebrick.type do
        fields! fulfill: UpdateFulfillHtlc,
                to: Origin,
                htlc: UpdateAddHtlc
      end
      ForwardFail = Algebrick.type do
        fields! fail: UpdateFailHtlc,
                to: Origin,
                htlc: UpdateAddHtlc
      end
      ForwardFailMalformed = Algebrick.type do
        fields! fail: UpdateFailMalformedHtlc,
                to: Origin,
                htlc: UpdateAddHtlc
      end

      attr_accessor :context

      def initialize(context)
        @context = context
        @channel_updates = {}

        context.broadcast << [:subscribe, ChannelStateChanged]
        context.broadcast << [:subscribe, LocalChannelUpdate]
        context.broadcast << [:subscribe, LocalChannelDown]
      end

      def on_message(message)
        match message, (on ~ChannelStateChanged do |msg|
        end), (on ~LocalChannelUpdate do |msg|
          @channel_updates[msg[:short_channel_id]] = msg[:channel_update]
        end), (on ~LocalChannelDown do |msg|
          @channel_updates.delete(msg[:short_channel_id])
        end), (on ~ForwardAdd do |add|
          add = message[:add]
          hop_data, next_packet, secret = Sphinx.parse(context.node_params.private_key, add.onion_routing_packet.htb)

          command = packet_to_command(hop_data, next_packet, add)
          case command
          when CommandFailHtlc
            parent << command
          when CommandAddHtlc
            context.register << Register::ForwardShortId[hop_data.per_hop.short_channel_id, command]
          when UpdateAddHtlc
            context.payment_handler << command
          end
        end), (on ForwardFulfill.(~any, ~Local, UpdateAddHtlc) do |fulfill, origin|
          htlc = message[:htlc]
          payment_hash = Bitcoin.sha256(fulfill[:payment_preimage].htb).bth
          context.broadcast << PaymentSucceeded[
            htlc.amount_msat, payment_hash, fulfill[:payment_preimage], []
          ]
        end), (on ForwardFulfill.(~any, ~Relayed, any) do |fulfill, origin|
          command = CommandFulfillHtlc[origin[:original_htlc_id], fulfill[:payment_preimage], true]
          context.register << Register::Forward[origin[:original_channel_id], command]
          payment_hash = Bitcoin.sha256(fulfill[:payment_preimage].htb).bth
          context.broadcast << PaymentRelayed[origin[:amount_msat_in], origin[:amount_msat_out], payment_hash]
          # preimage_db.add_preimage(origin[:original_channel_id],origin[:original_htlc_id], fulfill[:payment_preimage])
        end), (on ForwardFail.(~any, ~Local, UpdateAddHtlc) do |fail, origin|
          htlc = message[:htlc]
          context.broadcast << PaymentFailed[htlc[:payment_hash], []]
        end), (on ForwardFail.(~any, ~Relayed, any) do |fail, origin|
          command = CommandFailHtlc[origin[:original_htlc_id], fail[:reason], true]
          context.register << Register::Forward[origin[:original_channel_id], command]
        end), (on ForwardFailMalformed.(~any, ~Local, UpdateAddHtlc) do |fail, origin|
          htlc = message[:htlc]
          context.broadcast << PaymentFailed[htlc[:payment_hash], []]
        end), (on ForwardFailMalformed.(~any, ~Relayed, any) do |fail, origin|
          command = CommandFailMalformedHtlc[origin[:original_htlc_id], fail[:sha256_of_onion], fail[:failure_code], true]
          context.register << Register::Forward[origin[:original_channel_id], command]
        end), (on 'ok' do |msg|
        end), (on :channel_updates do
          @channel_updates
        end), (on any do

        end)
      end

      def packet_to_command(hop_data, packet, add)
        if packet.last?
          if hop_data.per_hop.amt_to_forward > add.amount_msat
            CommandFailHtlc[add.id, FinalIncorrectHtlcAmount[add.amount_msat], true]
          elsif hop_data.per_hop.outgoing_cltv_value != add.cltv_expiry
            CommandFailHtlc[add.id, FinalIncorrectCltvExpiry[add.cltv_expiry], true]
          elsif add.cltv_expiry < block_height + 3
            CommandFailHtlc[add.id, FinalExpiryTooSoon, true]
          else
            add
          end
        else
          channel_update = @channel_updates[hop_data.per_hop.short_channel_id]
          if !channel_update
            CommandFailHtlc[add.id, UnknownNextPeer[true]]
          elsif channel_update.channel_flags.to_i(16) & 64 == 64
            reason =  ChannelDisabled[channel_update.channel_flags.to_s(16), channel_update.to_payload.bth]
            CommandFailHtlc[add.id, reason, true]
          elsif add.amount_msat < channel_update.htlc_minimum_msat
            CommandFailHtlc[add.id, AmountBelowMinimum[add.amount_msat, channel_update.to_payload.bth], true]
          elsif add.cltv_expiry != hop_data.per_hop.outgoing_cltv_value + channel_update.cltv_expiry_delta
            CommandFailHtlc[add.id, IncorrectCltvExpiry[add.cltv_expiry, channel_update.to_payload.bth], true]
          elsif add.cltv_expiry < block_height + 3
            CommandFailHtlc[add.id, ExpiryTooSoon[channel_update.to_payload.bth], true]
          else
            CommandAddHtlc[hop_data.per_hop.amt_to_forward, add.payment_hash, hop_data.per_hop.outgoing_cltv_value, packet.to_payload.bth, Some[UpdateAddHtlc][add], true]
          end
        end
      end

      def block_height
        context.spv.blockchain_info['headers']
      end
    end
  end
end
