# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::Scripts do
  # see https://github.com/lightningnetwork/
  # lightning-rfc/blob/master/03-transactions.md#appendix-c-commitment-and-htlc-transaction-test-vectors
  let(:revocation_pubkey) { '0212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b19' }
  let(:local_delayed_payment_pubkey) { '03fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c' }
  let(:local_htlckey) { '030d417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e7' }
  let(:remote_htlckey) { '0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b' }
  let(:cltv_expiry) { 500 }

  describe '.to_local' do
    subject { described_class.to_local(revocation_pubkey, local_delayed_payment_pubkey, to_self_delay: 144) }

    let(:payload) do
      '63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402' \
      'bf2b1967029000b2752103fd5960528dc152014952efdb702a88f71e3c1653b2' \
      '314431701ec77e57fde83c68ac'
    end

    it { expect(subject.to_hex).to eq payload }
  end
  describe '.offered_htlc' do
    subject { described_class.offered_htlc(revocation_pubkey, local_htlckey, remote_htlckey, payment_preimage) }

    let(:payment_preimage) { '0202020202020202020202020202020202020202020202020202020202020202' }
    let(:payload) do
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '20876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca81' \
      '3e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5' \
      'd188ac6868'
    end

    it { expect(subject.to_hex).to eq payload }
  end
  describe '.received_htlc' do
    subject do
      described_class.received_htlc(
        revocation_pubkey,
        local_htlckey,
        remote_htlckey,
        payment_preimage,
        cltv_expiry
      )
    end

    let(:payment_preimage) { '0000000000000000000000000000000000000000000000000000000000000000' }
    let(:payload) do
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '208763a914b8bcb07f6344b42ab04250c86a6e8b75d3fdbbc688527c21030d41' \
      '7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae' \
      '677502f401b175ac6868'
    end

    it { expect(subject.to_hex).to eq payload }
  end
end
