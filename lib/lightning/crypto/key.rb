# frozen_string_literal: true

module Lightning
  module Crypto
    module Key
      # base_point. Binary String
      # per_commitment_point. Binary String
      def self.derive_public_key(base_point, per_commitment_point)
        # pubkey = basepoint + SHA256(per-commitment-point || basepoint)*G
        scalar = Bitcoin.sha256(per_commitment_point.htb + base_point.htb).bth.to_i(16)
        public_key = ECDSA::Group::Secp256k1.generator.multiply_by_scalar(scalar)
        point = Bitcoin::Key.new(pubkey: base_point).to_point + public_key
        pubkey = ECDSA::Format::PointOctetString.encode(point, compression: true)
        pubkey.bth
      end

      def self.derive_private_key(base_point_secret, per_commitment_point)
        # secretkey = basepoint-secret + SHA256(per-commitment-point || basepoint)

        basepoint = Bitcoin::Key.new(priv_key: base_point_secret)
        secret_key =
          base_point_secret.to_i(16) +
          Bitcoin.sha256(per_commitment_point.htb + basepoint.pubkey.htb).bth.to_i(16)

        secret_key.to_s(16).rjust(32, '0')
      end

      def self.per_commitment_point(seed, index)
        # per_commitment_point = per_commitment_secret * G
        Bitcoin::Key.new(priv_key: per_commitment_secret(seed, index)).pubkey
      end

      def self.revocation_public_key(base_point, per_commitment_point)
        # revocationkey =
        #     revocation_basepoint * SHA256(revocation_basepoint || per_commitment_point) +
        #     per_commitment_point * SHA256(per_commitment_point || revocation_basepoint)
        a = Bitcoin.sha256(base_point.htb + per_commitment_point.htb).bth.to_i(16)
        b = Bitcoin.sha256(per_commitment_point.htb + base_point.htb).bth.to_i(16)
        point_a = Bitcoin::Key.new(pubkey: base_point).to_point * a
        point_b = Bitcoin::Key.new(pubkey: per_commitment_point).to_point * b
        pubkey = ECDSA::Format::PointOctetString.encode(point_a + point_b, compression: true)
        pubkey.bth
      end

      def self.revocation_private_key(secret, per_commitment_secret)
        # revocationsecretkey =
        #     revocation_basepoint_secret * SHA256(revocation_basepoint || per_commitment_point) +
        #     per_commitment_secret * SHA256(per_commitment_point || revocation_basepoint)
        secret_point = Bitcoin::Key.new(priv_key: secret)
        per_commitment_point = Bitcoin::Key.new(priv_key: per_commitment_secret)
        a = Bitcoin.sha256(secret_point.pubkey.htb + per_commitment_point.pubkey.htb).bth.to_i(16)
        b = Bitcoin.sha256(per_commitment_point.pubkey.htb + secret_point.pubkey.htb).bth.to_i(16)
        secret_a = secret.to_i(16) * a
        secret_b = per_commitment_secret.to_i(16) * b
        ((secret_a + secret_b) % ECDSA::Group::Secp256k1.order).to_s(16).rjust(64, '0')
      end

      def self.per_commitment_secret(seed, index)
        # Lightning::Crypto::ShaChain.generate_from_seed(seed, index)
        Lightning::Crypto::ShaChain.generate_from_seed(seed, 0xFFFFFFFFFFFF - index)
      end
    end
  end
end
