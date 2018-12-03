# frozen_string_literal: true

module Lightning
  module Transactions
    module Scripts
      include Bitcoin::Opcodes
      def self.to_local(revocation_pubkey, local_delayed_payment_pubkey, to_self_delay: 1440)
        # OP_IF
        #     # Penalty transaction
        #     <revocationkey>
        # OP_ELSE
        #     `to_self_delay`
        #     OP_CSV
        #     OP_DROP
        #     <local_delayedkey>
        # OP_ENDIF
        # OP_CHECKSIG
        script = Bitcoin::Script.new
        script << OP_IF
        script <<   revocation_pubkey
        script << OP_ELSE
        script <<   encode_number(to_self_delay) << OP_CHECKSEQUENCEVERIFY << OP_DROP
        script <<   local_delayed_payment_pubkey
        script << OP_ENDIF
        script << OP_CHECKSIG
        script
      end

      def self.to_remote(remote_payment_pubkey)
        pubkey_hash = Bitcoin.hash160(remote_payment_pubkey)
        Bitcoin::Script.to_p2wpkh(pubkey_hash)
      end

      def self.offered_htlc(
        revocation_pubkey,
        local_htlckey,
        remote_htlckey,
        payment_preimage
      )
        # To you with revocation key
        # OP_DUP OP_HASH160 <RIPEMD160(SHA256(revocationkey))> OP_EQUAL
        # OP_IF
        #   OP_CHECKSIG
        # OP_ELSE
        #   <remote_htlckey> OP_SWAP OP_SIZE 32 OP_EQUAL
        #   OP_NOTIF
        #       # To me via HTLC-timeout transaction (timelocked).
        #       OP_DROP 2 OP_SWAP <local_htlckey> 2 OP_CHECKMULTISIG
        #   OP_ELSE
        #       # To you with preimage.
        #       OP_HASH160 <RIPEMD160(payment_hash)> OP_EQUALVERIFY
        #       OP_CHECKSIG
        #   OP_ENDIF
        # OP_ENDIF
        script = Bitcoin::Script.new
        script << OP_DUP << OP_HASH160 << Bitcoin.hash160(revocation_pubkey) << OP_EQUAL
        script << OP_IF
        script <<     OP_CHECKSIG
        script << OP_ELSE
        script <<     remote_htlckey << OP_SWAP << OP_SIZE << encode_number(32) << OP_EQUAL
        script <<     OP_NOTIF
        script <<         OP_DROP << encode_number(2) << OP_SWAP << local_htlckey << encode_number(2) << OP_CHECKMULTISIG
        script <<     OP_ELSE
        script <<         OP_HASH160 << Bitcoin.hash160(payment_preimage) << OP_EQUALVERIFY
        script <<         OP_CHECKSIG
        script <<     OP_ENDIF
        script << OP_ENDIF
        script
      end

      def self.received_htlc(
        revocation_pubkey,
        local_htlckey,
        remote_htlckey,
        payment_preimage,
        cltv_expiry
      )
        # # To you with revocation key
        # OP_DUP OP_HASH160 <RIPEMD160(SHA256(revocationkey))> OP_EQUAL
        # OP_IF
        #     OP_CHECKSIG
        # OP_ELSE
        #     <remote_htlckey> OP_SWAP
        #         OP_SIZE 32 OP_EQUAL
        #     OP_IF
        #         # To me via HTLC-success transaction.
        #         OP_HASH160 <RIPEMD160(payment_hash)> OP_EQUALVERIFY
        #         2 OP_SWAP <local_htlckey> 2 OP_CHECKMULTISIG
        #     OP_ELSE
        #         # To you after timeout.
        #         OP_DROP <cltv_expiry> OP_CHECKLOCKTIMEVERIFY OP_DROP
        #         OP_CHECKSIG
        #     OP_ENDIF
        # OP_ENDIF
        script = Bitcoin::Script.new
        script << OP_DUP << OP_HASH160 << Bitcoin.hash160(revocation_pubkey) << OP_EQUAL
        script << OP_IF
        script <<     OP_CHECKSIG
        script << OP_ELSE
        script <<     remote_htlckey << OP_SWAP << OP_SIZE << encode_number(32) << OP_EQUAL
        script <<     OP_IF
        script <<         OP_HASH160 << Bitcoin.hash160(payment_preimage) << OP_EQUALVERIFY
        script <<         encode_number(2) << OP_SWAP << local_htlckey << encode_number(2) << OP_CHECKMULTISIG
        script <<     OP_ELSE
        script <<         OP_DROP << encode_number(cltv_expiry) << OP_CHECKLOCKTIMEVERIFY << OP_DROP
        script <<         OP_CHECKSIG
        script <<     OP_ENDIF
        script << OP_ENDIF
        script
      end

      def self.encode_number(n)
        return Bitcoin::Opcodes.small_int_to_opcode(n) if -1 <= n && n <= 16
        Bitcoin::Script.encode_number(n)
      end
    end
  end
end
