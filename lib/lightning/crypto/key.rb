# frozen_string_literal: true

module Lightning
  module Crypto
    module Key
      OPENSSL_EC_GROUP = OpenSSL::PKey::EC::Group.new("secp256k1")

      # base_point. Binary String
      # per_commitment_point. Binary String
      def self.derive_public_key(base_point, per_commitment_point)
        # pubkey = basepoint + SHA256(per-commitment-point || basepoint)*G
        private_key = Bitcoin.sha256(per_commitment_point.htb + base_point.htb).bth
        public_key = Bitcoin::Key.new(priv_key: private_key).to_point
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

        secret_key.to_s(16).rjust(64, '0')
      end

      def self.per_commitment_point(seed, index)
        # per_commitment_point = per_commitment_secret * G
        Bitcoin::Key.new(priv_key: per_commitment_secret(seed, index)).pubkey
      end

      def self.revocation_public_key(base_point, per_commitment_point)
        # revocationkey =
        #     revocation_basepoint * SHA256(revocation_basepoint || per_commitment_point) +
        #     per_commitment_point * SHA256(per_commitment_point || revocation_basepoint)
        if support_openssl?
          revocation_public_key_open_ssl(base_point, per_commitment_point)
        else
          revocation_public_key_pure(base_point, per_commitment_point)
        end
      end

      def self.support_openssl?
        !!OpenSSL::PKey::EC.builtin_curves.find {|pair| pair[0] == 'secp256k1'}
      end

      def self.revocation_public_key_pure(base_point, per_commitment_point)
        a = Bitcoin.sha256(base_point.htb + per_commitment_point.htb).bth.to_i(16)
        b = Bitcoin.sha256(per_commitment_point.htb + base_point.htb).bth.to_i(16)
        point_a = Bitcoin::Key.new(pubkey: base_point).to_point * a
        point_b = Bitcoin::Key.new(pubkey: per_commitment_point).to_point * b
        pubkey = ECDSA::Format::PointOctetString.encode(point_a + point_b, compression: true)
        pubkey.bth
      end

      def self.revocation_public_key_open_ssl(base_point, per_commitment_point)
        a = Bitcoin.sha256(base_point.htb + per_commitment_point.htb).bth.to_i(16)
        b = Bitcoin.sha256(per_commitment_point.htb + base_point.htb).bth.to_i(16)

        openssl_base_point = OpenSSL::PKey::EC::Point.new(OPENSSL_EC_GROUP,  OpenSSL::BN.new(base_point.htb, 2))
        openssl_per_commitment_point = OpenSSL::PKey::EC::Point.new(OPENSSL_EC_GROUP,  OpenSSL::BN.new(per_commitment_point.htb, 2))

        openssl_point_a = openssl_base_point.mul(a)
        openssl_point_b = openssl_per_commitment_point.mul(b)

        openssl_key_a = Bitcoin::Key.new(pubkey: openssl_point_a.to_bn.to_s(16), key_type: 0)
        openssl_key_b = Bitcoin::Key.new(pubkey: openssl_point_b.to_bn.to_s(16), key_type: 0)
        openssl_pubkey = ECDSA::Format::PointOctetString.encode(openssl_key_a.to_point + openssl_key_b.to_point, compression: true)
        openssl_pubkey.bth
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
