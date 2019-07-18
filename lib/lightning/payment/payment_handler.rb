# frozen_string_literal: true

module Lightning
  module Payment
    class PaymentHandler < Concurrent::Actor::Context
      include Algebrick::Matching
      include Lightning::Channel::Messages
      include Lightning::Payment::Messages
      include Lightning::Wire::LightningMessages

      attr_reader :context, :preimages

      def initialize(context)
        @context = context
        @preimages = {}
      end

      def on_message(message)
        case message
        when ReceivePayment
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
          amount, multiplier = Lightning::Invoice.msat_to_readable(message[:amount_msat])
          invoice = Lightning::Invoice::Message.new.tap do |m|
            m.prefix = prefix
            m.amount = amount
            m.multiplier = multiplier
            m.timestamp = Time.now.to_i
            m.payment_hash = payment_hash
            m.description = message[:description]
            m.expiry = expiry
            m.sign(Bitcoin::Key.new(priv_key: key))
          end
          preimages[payment_hash] = [preimage, invoice]
          envelope.sender << invoice if envelope.sender.is_a? Concurrent::Actor::Reference
          invoice
        when UpdateAddHtlcMessage
          preimage, = preimages[message.payment_hash]
          return unless preimage
          command = CommandFulfillHtlc[message.id, preimage, true]
          context.register << Lightning::Channel::Register::Forward[message.channel_id, command]
          context.broadcast << Lightning::Payment::Events::PaymentReceived.new(
            channel_id: message.channel_id,
            amount_msat: message.amount_msat,
            payment_hash: message.payment_hash
          )
          preimages.delete(message.payment_hash)
        when :preimages
          preimages
        end
      end
    end
  end
end
