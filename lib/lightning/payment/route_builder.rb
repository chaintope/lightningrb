# frozen_string_literal: true

module Lightning
  module Payment
    module RouteBuilder
      include Lightning::Channel::Messages
      include Lightning::Crypto
      include Lightning::Onion
      include Algebrick

      def node_fee(base_msat, proportional, msat)
        base_msat + (proportional * msat) / 1000000
      end

      def build_command(amount_msat, expiry, payment_hash, hops)
        output = build_payloads(amount_msat, expiry, hops[1..-1])
        first_amount_msat = output[:msat]
        final_expiry = output[:expiry]
        payloads = output[:payloads]
        nodes = hops.map(&:next_node_id)
        onion, shared_secrets = build_onion(nodes, payloads, payment_hash)
        [
          CommandAddHtlc[first_amount_msat, payment_hash, final_expiry, onion.to_payload.bth, None, true],
          shared_secrets,
        ]
      end

      def build_payloads(amount_msat, expiry, hops)
        first_payload = { msat: amount_msat, expiry: expiry, payloads: [PerHop.new(0, amount_msat, expiry, "\x00" * 12)] }
        hops.reverse.inject(first_payload) do |payloads, hop|
          fee = node_fee(hop.last_update.fee_base_msat, hop.last_update.fee_proportional_millionths, payloads[:msat])
          {
            msat: payloads[:msat] + fee,
            expiry: payloads[:expiry] + hop.last_update.cltv_expiry_delta,
            payloads: [PerHop.new(hop.last_update.short_channel_id, payloads[:msat], payloads[:expiry], "\x00" * 12)] + payloads[:payloads],
          }
        end
      end

      def build_onion(nodes, payloads, payment_hash)
        session_key = SecureRandom.hex(32)
        payloads = payloads.map(&:to_payload).map(&:bth).map { |p| '00' + p }
        Sphinx.make_packet(session_key, nodes, payloads, payment_hash)
      end
    end
  end
end
