# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentHandler < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Channel::Messages
      include Lightning::Payment::Events
      include Lightning::Payment::Messages
      include Lightning::Wire::LightningMessages

      attr_reader :context, :preimages

      def initialize(context)
        @context = context
        @preimages = {}
      end

      def on_message(message)
        match message, (on ~ReceivePayment do |payment|
          preimage = SecureRandom.hex(32)
          payment_hash = Bitcoin.sha256(preimage.htb).bth
          # FIXME: expiry from message or default
          expiry = 600
          prefix =
            if Bitcoin.chain_params.mainnet?
              'lnbc'
            elsif Bitcoin.chain_params.testnet?
              'lntb'
            elsif Bitcoin.chain_params.regtest?
              'lnbcrt'
            end
          key = context.node_params.private_key
          amount, multiplier = Lightning::Invoice.msat_to_readable(payment[:amount_msat])
          invoice = Lightning::Invoice::Message.new.tap do |m|
            m.prefix = prefix
            m.amount = amount
            m.multiplier = multiplier
            m.timestamp = Time.now.to_i
            m.payment_hash = payment_hash
            m.description = payment[:description]
            m.expiry = expiry
            m.sign(Bitcoin::Key.new(priv_key: key))
          end
          preimages[payment_hash] = [preimage, invoice]
          envelope.sender << invoice if envelope.sender.is_a? Concurrent::Actor::Reference
          invoice
        end), (on ~UpdateAddHtlc do |htlc|
          preimage, = preimages[htlc[:payment_hash]]
          command = CommandFulfillHtlc[htlc.id, preimage, true]
          context.register << Lightning::Channel::Register::Forward[htlc[:channel_id], command]
          context.broadcast << PaymentReceived[htlc[:amount_msat], htlc[:payment_hash], htlc[:channel_id]]
          preimages.delete(htlc[:payment_hash])
        end), (on :preimages do
          preimages
        end)
      end
    end
  end
end
