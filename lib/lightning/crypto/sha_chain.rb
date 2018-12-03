# frozen_string_literal: true

module Lightning
  module Crypto
    module ShaChain
      class << self
        def generate_from_seed(seed, index)
          # generate_from_seed(seed, I):
          #   P = seed
          #   for B in 47 down to 0:
          #       if B set in I:
          #           flip(B) in P
          #           P = SHA256(P)
          #   return P
          value = seed.htb
          (0...48).reverse_each do |b|
            if index[b] == 1
              value = flip(b, value)
              value = Bitcoin.sha256(value)
            end
          end
          value.bth
        end

        # Return I'th secret given base secret whose index has bits..47 the same.
        def derive_secret(base, bits, index)
          value = base.htb
          (0...bits).reverse_each do |b|
            if index[b] == 1
              value = flip(b, value)
              value = Bitcoin.sha256(value)
            end
          end
          value.bth
        end

        def insert_secret(secret, index, known)
          # This tracks the index of the secret in each bucket across the traversal.
          count = where_to_put_secret(index)
          (0...count).each do |b|
            if derive_secret(secret, count, known[b][:index]) != known[b][:secret]
              raise "the secret for index #{index} is incorrect"
            end
          end
          # Assuming this automatically extends known[] as required.
          known[count] = { index: index, secret: secret }
          known
        end

        def derive_old_secret(index, secrets)
          (0...secrets.size).each do |b|
            # Mask off the non-zero prefix of the index.
            mask = ~((1 << b) - 1)
            if (index & mask) == secrets[b][:index]
              known = secrets[b][:secret]
              return derive_secret(known, b, index)
            end
          end
          raise "index #{index} hasn't been received yet."
        end

        private

        # alternates the B'th least significant bit in the value P.
        def flip(b, p)
          bits = p.unpack('b*').first
          bits[b] = bits[b] == '1' ? '0' : '1'
          [bits].pack('b*')
        end

        # a.k.a. count trailing 0s
        def where_to_put_secret(index)
          (0...48).each do |b|
            if index[b] == 1
              return b
            end
          end
          # I = 0, this is the seed.
          48
        end
      end
    end
  end
end
