# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions do
  let(:local_funding_pubkey) { '023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb' }
  let(:remote_funding_pubkey) { '030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c1' }
  let(:redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '5221023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe43' \
      '6f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3' \
      'c39fa711c152ae'.htb
    )
  end
  let(:script_pubkey) { Bitcoin::Script.to_p2wsh(redeem_script) }
  let(:commitment_input_utxo) do
    Lightning::Transactions::Utxo.new(
      10_000_000,
      script_pubkey,
      '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6be',
      0,
      redeem_script
    )
  end
  let(:commit_tx_number) { 42 }
  let(:local_payment_basepoint) { '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa' }
  let(:remote_payment_basepoint) { '032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991' }
  let(:local_is_funder) { true }
  let(:local_dust_limit_satoshis) { 546 }
  let(:local_revocation_pubkey) { '0212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b19' }
  let(:to_local_delay) { 144 }
  let(:local_delayed_payment_pubkey) { '03fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c' }
  let(:remote_payment_pubkey) { '0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b' }
  let(:local_htlc_pubkey) { '030d417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e7' }
  let(:remote_htlc_pubkey) { '0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b' }
  let(:keys) do
    [
      '0000000000000000000000000000000000000000000000000000000000000000',
      '0101010101010101010101010101010101010101010101010101010101010101',
      '0202020202020202020202020202020202020202020202020202020202020202',
      '0303030303030303030303030303030303030303030303030303030303030303',
      '0404040404040404040404040404040404040404040404040404040404040404',
    ]
  end
  let(:receive0) { build(:update_add_htlc, amount_msat: 1_000_000, payment_hash: keys[0], cltv_expiry: 500) }
  let(:receive1) { build(:update_add_htlc, amount_msat: 2_000_000, payment_hash: keys[1], cltv_expiry: 501) }
  let(:offer2) { build(:update_add_htlc, amount_msat: 2_000_000, payment_hash: keys[2], cltv_expiry: 502) }
  let(:offer3) { build(:update_add_htlc, amount_msat: 3_000_000, payment_hash: keys[3], cltv_expiry: 503) }
  let(:receive4) { build(:update_add_htlc, amount_msat: 4_000_000, payment_hash: keys[4], cltv_expiry: 504) }
  let(:htlc0) { build(:directed_htlc, :received, add: receive0).get }
  let(:htlc1) { build(:directed_htlc, :received, add: receive1).get }
  let(:htlc2) { build(:directed_htlc, :offered, add: offer2).get }
  let(:htlc3) { build(:directed_htlc, :offered, add: offer3).get }
  let(:htlc4) { build(:directed_htlc, :received, add: receive4).get }
  let(:spec) { Lightning::Transactions::CommitmentSpec[htlcs, local_feerate_per_kw, 6_988_000_000, 3_000_000_000] }

  let(:commitment_tx) do
    Lightning::Transactions::Commitment.make_commitment_tx(
      commitment_input_utxo,
      commit_tx_number,
      local_payment_basepoint,
      remote_payment_basepoint,
      local_is_funder,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      remote_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      spec
    ).tx.tap do |tx|
      Lightning::Transactions.add_sigs(
        tx, commitment_input_utxo, local_funding_pubkey, remote_funding_pubkey, local_sig, remote_sig
      )
    end
  end
  let(:htlc0_script) { Bitcoin::Script.to_p2wsh(htlc0_redeem_script) }
  let(:htlc0_redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '208763a914b8bcb07f6344b42ab04250c86a6e8b75d3fdbbc688527c21030d41' \
      '7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae' \
      '677502f401b175ac6868'.htb
    )
  end
  let(:htlc_success_tx_0) do
    Lightning::Transactions::HtlcSuccess.make_htlc_success_tx(
      commitment_tx,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      local_feerate_per_kw,
      htlc0.add
    ).tap do |tx_with_utxo|
      tx_with_utxo.add_sigs(local_htlc_signature_0, remote_htlc_signature_0, keys[0])
    end
  end

  let(:htlc2_script) { Bitcoin::Script.to_p2wsh(htlc2_redeem_script) }
  let(:htlc2_redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '20876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca81' \
      '3e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5' \
      'd188ac6868'.htb
    )
  end
  let(:htlc_timeout_tx_2) do
    Lightning::Transactions::HtlcTimeout.make_htlc_timeout_tx(
      commitment_tx,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      local_feerate_per_kw,
      htlc2.add
    ).tap do |tx_with_utxo|
      tx_with_utxo.add_sigs(local_htlc_signature_2, remote_htlc_signature_2)
    end
  end

  let(:htlc1_script) { Bitcoin::Script.to_p2wsh(htlc1_redeem_script) }
  let(:htlc1_redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '208763a914b8bcb07f6344b42ab04250c86a6e8b75d3fdbbc688527c21030d41' \
      '7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae' \
      '677502f401b175ac6868'.htb
    )
  end
  let(:htlc_success_tx_1) do
    Lightning::Transactions::HtlcSuccess.make_htlc_success_tx(
      commitment_tx,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      local_feerate_per_kw,
      htlc1.add
    ).tap do |tx_with_utxo|
      tx_with_utxo.add_sigs(local_htlc_signature_1, remote_htlc_signature_1, keys[1])
    end
  end

  let(:htlc3_script) { Bitcoin::Script.to_p2wsh(htlc3_redeem_script) }
  let(:htlc3_redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '20876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca81' \
      '3e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d' \
      '5b88ac6868'.htb
    )
  end
  let(:htlc_timeout_tx_3) do
    Lightning::Transactions::HtlcTimeout.make_htlc_timeout_tx(
      commitment_tx,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      local_feerate_per_kw,
      htlc3.add
    ).tap do |tx_with_utxo|
      tx_with_utxo.add_sigs(local_htlc_signature_3, remote_htlc_signature_3)
    end
  end

  let(:htlc4_script) { Bitcoin::Script.to_p2wsh(htlc4_redeem_script) }
  let(:htlc4_redeem_script) do
    Bitcoin::Script.parse_from_payload(
      '76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854a' \
      'a6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201' \
      '208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41' \
      '7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae' \
      '677502f801b175ac6868'.htb
    )
  end
  let(:htlc_success_tx_4) do
    Lightning::Transactions::HtlcSuccess.make_htlc_success_tx(
      commitment_tx,
      local_dust_limit_satoshis,
      local_revocation_pubkey,
      to_local_delay,
      local_delayed_payment_pubkey,
      local_htlc_pubkey,
      remote_htlc_pubkey,
      local_feerate_per_kw,
      htlc4.add
    ).tap do |tx_with_utxo|
      tx_with_utxo.add_sigs(local_htlc_signature_4, remote_htlc_signature_4, keys[4])
    end
  end

  describe 'simple commitment tx with no HTLCs' do
    # to_local_msat: 7000000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 15000
    # # base commitment transaction fee = 10860
    # # actual commitment transaction fee = 10860
    # # to_local amount 6989140 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b2
    # 752103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 3045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c0860c613173de7d39e7968022041376d520e9c0e1ad
    # 52248ddf4b22e12be8763007df977253ef45a4ca3bdb7c0
    # # local_signature = 3044022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319e5185a46022055c419379c5051a78d
    # 00dbbce11b5b664a0c22815fbcc6fcef6b1937c3836939
    subject { commitment_tx }

    let(:spec) { Lightning::Transactions::CommitmentSpec[Set[], local_feerate_per_kw, 7_000_000_000, 3_000_000_000] }
    let(:local_feerate_per_kw) { 15_000 }
    let(:local_sig) do
      '3044022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319' \
      'e5185a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b' \
      '1937c3836939'
    end
    let(:remote_sig) do
      '3045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c0860c613173d' \
      'e7d39e7968022041376d520e9c0e1ad52248ddf4b22e12be8763007df977253e' \
      'f45a4ca3bdb7c0'
    end
    let(:expected) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8002c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de84311054a56a00000000002200204adb4e2f00' \
      '643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e0400473044' \
      '022051b75c73198c6deee1a875871c3961832909acd297c6b908d59e3319e518' \
      '5a46022055c419379c5051a78d00dbbce11b5b664a0c22815fbcc6fcef6b1937' \
      'c383693901483045022100f51d2e566a70ba740fc5d8c0f07b9b93d2ed741c3c' \
      '0860c613173de7d39e7968022041376d520e9c0e1ad52248ddf4b22e12be8763' \
      '007df977253ef45a4ca3bdb7c001475221023da092f6980e58d2c037173180e9' \
      'a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66' \
      'd5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    end

    it { expect(subject.to_payload.bth).to eq expected }
  end

  describe 'commitment tx with all five HTLCs untrimmed (minimum feerate)' do
    let(:htlcs) { Set[htlc0, htlc1, htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 0 }
    let(:local_sig) do
      '30440220275b0c325a5e9355650dc30c0eccfbc7efb23987c24b556b9dfdd40e' \
      'ffca18d202206caceb2c067836c51f296740c7ae807ffcbfbf1dd3a0d56b6de9' \
      'a5b247985f06'
    end
    let(:remote_sig) do
      '304402204fd4928835db1ccdfc40f5c78ce9bd65249b16348df81f0c44328dcd' \
      'efc97d630220194d3869c38bc732dd87d13d2958015e2fc16829e74cd4377f84' \
      'd215c0b70606'
    end
    let(:local_htlc_signature_0) do
      '304402207cb324fa0de88f452ffa9389678127ebcf4cabe1dd848b8e076c1a19' \
      '62bf34720220116ed922b12311bd602d67e60d2529917f21c5b82f25ff6506c0' \
      'f87886b4dfd5'
    end
    let(:remote_htlc_signature_0) do
      '304402206a6e59f18764a5bf8d4fa45eebc591566689441229c918b480fb2af8' \
      'cc6a4aeb02205248f273be447684b33e3c8d1d85a8e0ca9fa0bae9ae33f0527a' \
      'da9c162919a6'
    end
    let(:local_htlc_signature_2) do
      '3045022100c89172099507ff50f4c925e6c5150e871fb6e83dd73ff9fbb72f6c' \
      'e829a9633f02203a63821d9162e99f9be712a68f9e589483994feae2661e4546' \
      'cd5b6cec007be5'
    end
    let(:remote_htlc_signature_2) do
      '3045022100d5275b3619953cb0c3b5aa577f04bc512380e60fa551762ce3d7a1' \
      'bb7401cff9022037237ab0dac3fe100cde094e82e2bed9ba0ed1bb40154b48e5' \
      '6aa70f259e608b'
    end
    let(:local_htlc_signature_1) do
      '3045022100def389deab09cee69eaa1ec14d9428770e45bcbe9feb46468ecf48' \
      '1371165c2f022015d2e3c46600b2ebba8dcc899768874cc6851fd1ecb3fffd15' \
      'db1cc3de7e10da'
    end
    let(:remote_htlc_signature_1) do
      '304402201b63ec807771baf4fdff523c644080de17f1da478989308ad13a58b5' \
      '1db91d360220568939d38c9ce295adba15665fa68f51d967e8ed14a007b75154' \
      '0a80b325f202'
    end
    let(:local_htlc_signature_3) do
      '30440220643aacb19bbb72bd2b635bc3f7375481f5981bace78cdd8319b2988f' \
      'fcc6704202203d27784ec8ad51ed3bd517a05525a5139bb0b755dd719e005433' \
      '2d186ac08727'
    end
    let(:remote_htlc_signature_3) do
      '3045022100daee1808f9861b6c3ecd14f7b707eca02dd6bdfc714ba2f33bc8cd' \
      'ba507bb182022026654bf8863af77d74f51f4e0b62d461a019561bb12acb120d' \
      '3f7195d148a554'
    end
    let(:local_htlc_signature_4) do
      '30440220549e80b4496803cbc4a1d09d46df50109f546d43fbbf86cd90b174b1' \
      '484acd5402205f12a4f995cb9bded597eabfee195a285986aa6d93ae5bb72507' \
      'ebc6a4e2349e'
    end
    let(:remote_htlc_signature_4) do
      '304402207e0410e45454b0978a623f36a10626ef17b27d9ad44e2760f98cfa3e' \
      'fb37924f0220220bd8acd43ecaa916a80bd4f919c495a2c58982ce7c8625153f' \
      '8596692a801d'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8007e80300000000000022002052bfef04' \
      '79d7b293c27e0f1eb294bea154c63a3294ef092c19af51409bce0e2ad0070000' \
      '00000000220020403d394747cae42e98ff01734ad5c08f82ba123d3d9a620abd' \
      'a88989651e2ab5d007000000000000220020748eba944fedc8827f6b06bc4467' \
      '8f93c0f9e6078b35c6331ed31e75f8ce0c2db80b000000000000220020c20b5d' \
      '1f8584fd90443e7b7b720136174fa4b9333c261d04dbbd012635c0f419a00f00' \
      '00000000002200208c48d15160397c9731df9bc3b236656efb6665fbfe92b4a6' \
      '878e88a499f741c4c0c62d0000000000160014ccf1af2f2aabee14bb40fa3851' \
      'ab2301de843110e0a06a00000000002200204adb4e2f00643db396dd120d4e7d' \
      'c17625f5f2c11a40d857accc862d6b7dd80e04004730440220275b0c325a5e93' \
      '55650dc30c0eccfbc7efb23987c24b556b9dfdd40effca18d202206caceb2c06' \
      '7836c51f296740c7ae807ffcbfbf1dd3a0d56b6de9a5b247985f060147304402' \
      '204fd4928835db1ccdfc40f5c78ce9bd65249b16348df81f0c44328dcdefc97d' \
      '630220194d3869c38bc732dd87d13d2958015e2fc16829e74cd4377f84d215c0' \
      'b7060601475221023da092f6980e58d2c037173180e9a465476026ee50f96695' \
      '963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385' \
      'a132cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_success_tx_0) do
      '020000000001018154ecccf11a5fb56c39654c4deb4d2296f83c69268280b94d' \
      '021370c94e219700000000000000000001e8030000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '4402206a6e59f18764a5bf8d4fa45eebc591566689441229c918b480fb2af8cc' \
      '6a4aeb02205248f273be447684b33e3c8d1d85a8e0ca9fa0bae9ae33f0527ada' \
      '9c162919a60147304402207cb324fa0de88f452ffa9389678127ebcf4cabe1dd' \
      '848b8e076c1a1962bf34720220116ed922b12311bd602d67e60d2529917f21c5' \
      'b82f25ff6506c0f87886b4dfd501200000000000000000000000000000000000' \
      '0000000000000000000000000000008a76a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c8201208763a914b8bcb07f6344b42ab04250' \
      'c86a6e8b75d3fdbbc688527c21030d417a46946384f88d5f3337267c5e579765' \
      '875dc4daca813e21734b140639e752ae677502f401b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_2) do
      '020000000001018154ecccf11a5fb56c39654c4deb4d2296f83c69268280b94d' \
      '021370c94e219701000000000000000001d0070000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100d5275b3619953cb0c3b5aa577f04bc512380e60fa551762ce3d7a1bb' \
      '7401cff9022037237ab0dac3fe100cde094e82e2bed9ba0ed1bb40154b48e56a' \
      'a70f259e608b01483045022100c89172099507ff50f4c925e6c5150e871fb6e8' \
      '3dd73ff9fbb72f6ce829a9633f02203a63821d9162e99f9be712a68f9e589483' \
      '994feae2661e4546cd5b6cec007be501008576a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a469463' \
      '84f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b4' \
      '3e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_success_tx_1) do
      '020000000001018154ecccf11a5fb56c39654c4deb4d2296f83c69268280b94d' \
      '021370c94e219702000000000000000001d0070000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '4402201b63ec807771baf4fdff523c644080de17f1da478989308ad13a58b51d' \
      'b91d360220568939d38c9ce295adba15665fa68f51d967e8ed14a007b751540a' \
      '80b325f20201483045022100def389deab09cee69eaa1ec14d9428770e45bcbe' \
      '9feb46468ecf481371165c2f022015d2e3c46600b2ebba8dcc899768874cc685' \
      '1fd1ecb3fffd15db1cc3de7e10da012001010101010101010101010101010101' \
      '010101010101010101010101010101018a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb' \
      '7bcea5afba3f3cdce23988527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f501b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '020000000001018154ecccf11a5fb56c39654c4deb4d2296f83c69268280b94d' \
      '021370c94e219703000000000000000001b80b0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100daee1808f9861b6c3ecd14f7b707eca02dd6bdfc714ba2f33bc8cdba' \
      '507bb182022026654bf8863af77d74f51f4e0b62d461a019561bb12acb120d3f' \
      '7195d148a554014730440220643aacb19bbb72bd2b635bc3f7375481f5981bac' \
      'e78cdd8319b2988ffcc6704202203d27784ec8ad51ed3bd517a05525a5139bb0' \
      'b755dd719e0054332d186ac0872701008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a48' \
      '6ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '020000000001018154ecccf11a5fb56c39654c4deb4d2296f83c69268280b94d' \
      '021370c94e219704000000000000000001a00f0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '4402207e0410e45454b0978a623f36a10626ef17b27d9ad44e2760f98cfa3efb' \
      '37924f0220220bd8acd43ecaa916a80bd4f919c495a2c58982ce7c8625153f85' \
      '96692a801d014730440220549e80b4496803cbc4a1d09d46df50109f546d43fb' \
      'bf86cd90b174b1484acd5402205f12a4f995cb9bded597eabfee195a285986aa' \
      '6d93ae5bb72507ebc6a4e2349e01200404040404040404040404040404040404' \
      '0404040404040404040404040404048a76a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23' \
      'e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e579765' \
      '875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_success_tx_0.tx.to_payload.bth).to eq expected_htlc_success_tx_0 }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_success_tx_1.tx.to_payload.bth).to eq expected_htlc_success_tx_1 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with seven outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 647
    # base commitment transaction fee = 1024
    # actual commitment transaction fee = 1024
    # HTLC 2 offered amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 0 received amount 1000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a914b8bcb07f6344b42ab04250c86a6e8b75d3fdbbc688527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f401b175ac6868
    # HTLC 1 received amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb7bcea5afba3f3cdce23988527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f501b175ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6986976 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc0, htlc1, htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 647 }
    let(:local_sig) do
      '304502210094bfd8f5572ac0157ec76a9551b6c5216a4538c07cd13a51af4a54' \
      'cb26fa14320220768efce8ce6f4a5efac875142ff19237c011343670adf9c7ac' \
      '69704a120d1163'
    end
    let(:remote_sig) do
      '3045022100a5c01383d3ec646d97e40f44318d49def817fcd61a0ef18008a665' \
      'b3e151785502203e648efddd5838981ef55ec954be69c4a652d021e6081a100d' \
      '034de366815e9b'
    end
    let(:local_htlc_signature_0) do
      '304402205999590b8a79fa346e003a68fd40366397119b2b0cdf37b149968d6b' \
      'c6fbcc4702202b1e1fb5ab7864931caed4e732c359e0fe3d86a548b557be2246' \
      'efb1708d579a'
    end
    let(:remote_htlc_signature_0) do
      '30440220385a5afe75632f50128cbb029ee95c80156b5b4744beddc729ad339c' \
      '9ca432c802202ba5f48550cad3379ac75b9b4fedb86a35baa6947f16ba5037fb' \
      '8b11ab343740'
    end
    let(:local_htlc_signature_2) do
      '304402207ff03eb0127fc7c6cae49cc29e2a586b98d1e8969cf4a17dfa50b9c2' \
      '647720b902205e2ecfda2252956c0ca32f175080e75e4e390e433feb1f8ce9f2' \
      'ba55648a1dac'
    end
    let(:remote_htlc_signature_2) do
      '304402207ceb6678d4db33d2401fdc409959e57c16a6cb97a30261d9c61f29b8' \
      'c58d34b90220084b4a17b4ca0e86f2d798b3698ca52de5621f2ce86f80bed79a' \
      'fa66874511b0'
    end
    let(:local_htlc_signature_1) do
      '3045022100d50d067ca625d54e62df533a8f9291736678d0b86c28a61bb2a80c' \
      'f42e702d6e02202373dde7e00218eacdafb9415fe0e1071beec1857d1af3c6a2' \
      '01a44cbc47c877'
    end
    let(:remote_htlc_signature_1) do
      '304402206a401b29a0dff0d18ec903502c13d83e7ec019450113f4a7655a4ce4' \
      '0d1f65ba0220217723a084e727b6ca0cc8b6c69c014a7e4a01fcdcba3e3993f4' \
      '62a3c574d833'
    end
    let(:local_htlc_signature_3) do
      '3045022100db9dc65291077a52728c622987e9895b7241d4394d6dcb916d7600' \
      'a3e8728c22022036ee3ee717ba0bb5c45ee84bc7bbf85c0f90f26ae4e4a25a6b' \
      '4241afa8a3f1cb'
    end
    let(:remote_htlc_signature_3) do
      '30450221009b1c987ba599ee3bde1dbca776b85481d70a78b681a8d84206723e' \
      '2795c7cac002207aac84ad910f8598c4d1c0ea2e3399cf6627a4e3e90131315b' \
      'c9f038451ce39d'
    end
    let(:local_htlc_signature_4) do
      '304402202d1a3c0d31200265d2a2def2753ead4959ae20b4083e19553acfffa5' \
      'dfab60bf022020ede134149504e15b88ab261a066de49848411e15e70f9e6a54' \
      '62aec2949f8f'
    end
    let(:remote_htlc_signature_4) do
      '3045022100cc28030b59f0914f45b84caa983b6f8effa900c952310708c2b5b0' \
      '0781117022022027ba2ccdf94d03c6d48b327f183f6e28c8a214d089b9227f94' \
      'ac4f85315274f0'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8007e80300000000000022002052bfef04' \
      '79d7b293c27e0f1eb294bea154c63a3294ef092c19af51409bce0e2ad0070000' \
      '00000000220020403d394747cae42e98ff01734ad5c08f82ba123d3d9a620abd' \
      'a88989651e2ab5d007000000000000220020748eba944fedc8827f6b06bc4467' \
      '8f93c0f9e6078b35c6331ed31e75f8ce0c2db80b000000000000220020c20b5d' \
      '1f8584fd90443e7b7b720136174fa4b9333c261d04dbbd012635c0f419a00f00' \
      '00000000002200208c48d15160397c9731df9bc3b236656efb6665fbfe92b4a6' \
      '878e88a499f741c4c0c62d0000000000160014ccf1af2f2aabee14bb40fa3851' \
      'ab2301de843110e09c6a00000000002200204adb4e2f00643db396dd120d4e7d' \
      'c17625f5f2c11a40d857accc862d6b7dd80e040048304502210094bfd8f5572a' \
      'c0157ec76a9551b6c5216a4538c07cd13a51af4a54cb26fa14320220768efce8' \
      'ce6f4a5efac875142ff19237c011343670adf9c7ac69704a120d116301483045' \
      '022100a5c01383d3ec646d97e40f44318d49def817fcd61a0ef18008a665b3e1' \
      '51785502203e648efddd5838981ef55ec954be69c4a652d021e6081a100d034d' \
      'e366815e9b01475221023da092f6980e58d2c037173180e9a465476026ee50f9' \
      '6695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf' \
      '6385a132cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_success_tx_0) do
      '020000000001018323148ce2419f21ca3d6780053747715832e18ac780931a51' \
      '4b187768882bb60000000000000000000122020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '440220385a5afe75632f50128cbb029ee95c80156b5b4744beddc729ad339c9c' \
      'a432c802202ba5f48550cad3379ac75b9b4fedb86a35baa6947f16ba5037fb8b' \
      '11ab3437400147304402205999590b8a79fa346e003a68fd40366397119b2b0c' \
      'df37b149968d6bc6fbcc4702202b1e1fb5ab7864931caed4e732c359e0fe3d86' \
      'a548b557be2246efb1708d579a01200000000000000000000000000000000000' \
      '0000000000000000000000000000008a76a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c8201208763a914b8bcb07f6344b42ab04250' \
      'c86a6e8b75d3fdbbc688527c21030d417a46946384f88d5f3337267c5e579765' \
      '875dc4daca813e21734b140639e752ae677502f401b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_2) do
      '020000000001018323148ce2419f21ca3d6780053747715832e18ac780931a51' \
      '4b187768882bb60100000000000000000124060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '4402207ceb6678d4db33d2401fdc409959e57c16a6cb97a30261d9c61f29b8c5' \
      '8d34b90220084b4a17b4ca0e86f2d798b3698ca52de5621f2ce86f80bed79afa' \
      '66874511b00147304402207ff03eb0127fc7c6cae49cc29e2a586b98d1e8969c' \
      'f4a17dfa50b9c2647720b902205e2ecfda2252956c0ca32f175080e75e4e390e' \
      '433feb1f8ce9f2ba55648a1dac01008576a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f8' \
      '8d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b43e1b' \
      '38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_success_tx_1) do
      '020000000001018323148ce2419f21ca3d6780053747715832e18ac780931a51' \
      '4b187768882bb6020000000000000000010a060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '4402206a401b29a0dff0d18ec903502c13d83e7ec019450113f4a7655a4ce40d' \
      '1f65ba0220217723a084e727b6ca0cc8b6c69c014a7e4a01fcdcba3e3993f462' \
      'a3c574d83301483045022100d50d067ca625d54e62df533a8f9291736678d0b8' \
      '6c28a61bb2a80cf42e702d6e02202373dde7e00218eacdafb9415fe0e1071bee' \
      'c1857d1af3c6a201a44cbc47c877012001010101010101010101010101010101' \
      '010101010101010101010101010101018a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb' \
      '7bcea5afba3f3cdce23988527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f501b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '020000000001018323148ce2419f21ca3d6780053747715832e18ac780931a51' \
      '4b187768882bb6030000000000000000010c0a0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '450221009b1c987ba599ee3bde1dbca776b85481d70a78b681a8d84206723e27' \
      '95c7cac002207aac84ad910f8598c4d1c0ea2e3399cf6627a4e3e90131315bc9' \
      'f038451ce39d01483045022100db9dc65291077a52728c622987e9895b7241d4' \
      '394d6dcb916d7600a3e8728c22022036ee3ee717ba0bb5c45ee84bc7bbf85c0f' \
      '90f26ae4e4a25a6b4241afa8a3f1cb01008576a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a469463' \
      '84f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a' \
      '486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '020000000001018323148ce2419f21ca3d6780053747715832e18ac780931a51' \
      '4b187768882bb604000000000000000001da0d0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100cc28030b59f0914f45b84caa983b6f8effa900c952310708c2b5b007' \
      '81117022022027ba2ccdf94d03c6d48b327f183f6e28c8a214d089b9227f94ac' \
      '4f85315274f00147304402202d1a3c0d31200265d2a2def2753ead4959ae20b4' \
      '083e19553acfffa5dfab60bf022020ede134149504e15b88ab261a066de49848' \
      '411e15e70f9e6a5462aec2949f8f012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_success_tx_0.tx.to_payload.bth).to eq expected_htlc_success_tx_0 }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_success_tx_1.tx.to_payload.bth).to eq expected_htlc_success_tx_1 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with six outputs untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 648
    # base commitment transaction fee = 914
    # actual commitment transaction fee = 1914
    # HTLC 2 offered amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 1 received amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb7bcea5afba3f3cdce23988527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f501b175ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6987086 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc1, htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 648 }
    let(:local_sig) do
      '3045022100a2270d5950c89ae0841233f6efea9c951898b301b2e89e0adbd2c6' \
      '87b9f32efa02207943d90f95b9610458e7c65a576e149750ff3accaacad004cd' \
      '85e70b235e27de'
    end
    let(:remote_sig) do
      '3044022072714e2fbb93cdd1c42eb0828b4f2eff143f717d8f26e79d6ada4f0d' \
      'cb681bbe02200911be4e5161dd6ebe59ff1c58e1997c4aea804f81db6b698821' \
      'db6093d7b057'
    end
    let(:local_htlc_signature_2) do
      '3045022100a4c574f00411dd2f978ca5cdc1b848c311cd7849c087ad2f21a5bc' \
      'e5e8cc5ae90220090ae39a9bce2fb8bc879d7e9f9022df249f41e25e51f1a9bf' \
      '6447a9eeffc098'
    end
    let(:remote_htlc_signature_2) do
      '3044022062ef2e77591409d60d7817d9bb1e71d3c4a2931d1a6c7c8307422c84' \
      'f001a251022022dad9726b0ae3fe92bda745a06f2c00f92342a186d84518588c' \
      'f65f4dfaada8'
    end
    let(:local_htlc_signature_1) do
      '304402207679cf19790bea76a733d2fa0672bd43ab455687a068f815a3d23758' \
      '1f57139a0220683a1a799e102071c206b207735ca80f627ab83d6616b4bcd017' \
      'c5d79ef3e7d0'
    end
    let(:remote_htlc_signature_1) do
      '3045022100e968cbbb5f402ed389fdc7f6cd2a80ed650bb42c79aeb2a5678444' \
      'af94f6c78502204b47a1cb24ab5b0b6fe69fe9cfc7dba07b9dd0d8b95f372c1d' \
      '9435146a88f8d4'
    end
    let(:local_htlc_signature_3) do
      '304402200df76fea718745f3c529bac7fd37923e7309ce38b25c0781e4cf514d' \
      'd9ef8dc802204172295739dbae9fe0474dcee3608e3433b4b2af3a2e6787108b' \
      '02f894dcdda3'
    end
    let(:remote_htlc_signature_3) do
      '3045022100aa91932e305292cf9969cc23502bbf6cef83a5df39c95ad04a707c' \
      '4f4fed5c7702207099fc0f3a9bfe1e7683c0e9aa5e76c5432eb20693bf4cb182' \
      'f04d383dc9c8c2'
    end
    let(:local_htlc_signature_4) do
      '304402200daf2eb7afd355b4caf6fb08387b5f031940ea29d1a9f35071288a83' \
      '9c9039e4022067201b562456e7948616c13acb876b386b511599b58ac1d94d12' \
      '7f91c50463a6'
    end
    let(:remote_htlc_signature_4) do
      '3044022035cac88040a5bba420b1c4257235d5015309113460bc33f2853cd81c' \
      'a36e632402202fc94fd3e81e9d34a9d01782a0284f3044370d03d60f3fc041e2' \
      'da088d2de58f'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8006d007000000000000220020403d3947' \
      '47cae42e98ff01734ad5c08f82ba123d3d9a620abda88989651e2ab5d0070000' \
      '00000000220020748eba944fedc8827f6b06bc44678f93c0f9e6078b35c6331e' \
      'd31e75f8ce0c2db80b000000000000220020c20b5d1f8584fd90443e7b7b7201' \
      '36174fa4b9333c261d04dbbd012635c0f419a00f0000000000002200208c48d1' \
      '5160397c9731df9bc3b236656efb6665fbfe92b4a6878e88a499f741c4c0c62d' \
      '0000000000160014ccf1af2f2aabee14bb40fa3851ab2301de8431104e9d6a00' \
      '000000002200204adb4e2f00643db396dd120d4e7dc17625f5f2c11a40d857ac' \
      'cc862d6b7dd80e0400483045022100a2270d5950c89ae0841233f6efea9c9518' \
      '98b301b2e89e0adbd2c687b9f32efa02207943d90f95b9610458e7c65a576e14' \
      '9750ff3accaacad004cd85e70b235e27de01473044022072714e2fbb93cdd1c4' \
      '2eb0828b4f2eff143f717d8f26e79d6ada4f0dcb681bbe02200911be4e5161dd' \
      '6ebe59ff1c58e1997c4aea804f81db6b698821db6093d7b05701475221023da0' \
      '92f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb2103' \
      '0e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c1' \
      '52ae3e195220'
    end
    let(:expected_htlc_timeout_tx_2) do
      '02000000000101579c183eca9e8236a5d7f5dcd79cfec32c497fdc0ec61533cd' \
      'e99ecd436cadd10000000000000000000123060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '44022062ef2e77591409d60d7817d9bb1e71d3c4a2931d1a6c7c8307422c84f0' \
      '01a251022022dad9726b0ae3fe92bda745a06f2c00f92342a186d84518588cf6' \
      '5f4dfaada801483045022100a4c574f00411dd2f978ca5cdc1b848c311cd7849' \
      'c087ad2f21a5bce5e8cc5ae90220090ae39a9bce2fb8bc879d7e9f9022df249f' \
      '41e25e51f1a9bf6447a9eeffc09801008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b43e' \
      '1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_success_tx_1) do
      '02000000000101579c183eca9e8236a5d7f5dcd79cfec32c497fdc0ec61533cd' \
      'e99ecd436cadd10100000000000000000109060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100e968cbbb5f402ed389fdc7f6cd2a80ed650bb42c79aeb2a5678444af' \
      '94f6c78502204b47a1cb24ab5b0b6fe69fe9cfc7dba07b9dd0d8b95f372c1d94' \
      '35146a88f8d40147304402207679cf19790bea76a733d2fa0672bd43ab455687' \
      'a068f815a3d237581f57139a0220683a1a799e102071c206b207735ca80f627a' \
      'b83d6616b4bcd017c5d79ef3e7d0012001010101010101010101010101010101' \
      '010101010101010101010101010101018a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb' \
      '7bcea5afba3f3cdce23988527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f501b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '02000000000101579c183eca9e8236a5d7f5dcd79cfec32c497fdc0ec61533cd' \
      'e99ecd436cadd1020000000000000000010b0a0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100aa91932e305292cf9969cc23502bbf6cef83a5df39c95ad04a707c4f' \
      '4fed5c7702207099fc0f3a9bfe1e7683c0e9aa5e76c5432eb20693bf4cb182f0' \
      '4d383dc9c8c20147304402200df76fea718745f3c529bac7fd37923e7309ce38' \
      'b25c0781e4cf514dd9ef8dc802204172295739dbae9fe0474dcee3608e3433b4' \
      'b2af3a2e6787108b02f894dcdda301008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a48' \
      '6ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '02000000000101579c183eca9e8236a5d7f5dcd79cfec32c497fdc0ec61533cd' \
      'e99ecd436cadd103000000000000000001d90d0000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '44022035cac88040a5bba420b1c4257235d5015309113460bc33f2853cd81ca3' \
      '6e632402202fc94fd3e81e9d34a9d01782a0284f3044370d03d60f3fc041e2da' \
      '088d2de58f0147304402200daf2eb7afd355b4caf6fb08387b5f031940ea29d1' \
      'a9f35071288a839c9039e4022067201b562456e7948616c13acb876b386b5115' \
      '99b58ac1d94d127f91c50463a601200404040404040404040404040404040404' \
      '0404040404040404040404040404048a76a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23' \
      'e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e579765' \
      '875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_success_tx_1.tx.to_payload.bth).to eq expected_htlc_success_tx_1 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with six outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 2069
    # base commitment transaction fee = 2921
    # actual commitment transaction fee = 3921
    # HTLC 2 offered amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 1 received amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0fb7bcea5afba3f3cdce23988527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f501b175ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6985079 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc1, htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 2069 }
    let(:local_sig) do
      '304402203ca8f31c6a47519f83255dc69f1894d9a6d7476a19f498d31eaf0cd3' \
      'a85eeb63022026fd92dc752b33905c4c838c528b692a8ad4ced959990b5d5ee2' \
      'ff940fa90eea'
    end
    let(:remote_sig) do
      '3044022001d55e488b8b035b2dd29d50b65b530923a416d47f377284145bc876' \
      '7b1b6a75022019bb53ddfe1cefaf156f924777eaaf8fdca1810695a7d0a247ad' \
      '2afba8232eb4'
    end
    let(:local_htlc_signature_2) do
      '3044022056eb1af429660e45a1b0b66568cb8c4a3aa7e4c9c292d5d6c47f86eb' \
      'f2c8838f022065c3ac4ebe980ca7a41148569be4ad8751b0a724a41405697ec5' \
      '5035dae66402'
    end
    let(:remote_htlc_signature_2) do
      '3045022100d1cf354de41c1369336cf85b225ed033f1f8982a01be503668df75' \
      '6a7e668b66022001254144fb4d0eecc61908fccc3388891ba17c5d7a1a8c62bd' \
      'd307e5a513f992'
    end
    let(:local_htlc_signature_1) do
      '3045022100914bb232cd4b2690ee3d6cb8c3713c4ac9c4fb925323068d8b07f6' \
      '7c8541f8d9022057152f5f1615b793d2d45aac7518989ae4fe970f28b9b5c775' \
      '04799d25433f7f'
    end
    let(:remote_htlc_signature_1) do
      '3045022100d065569dcb94f090345402736385efeb8ea265131804beac06dd84' \
      'd15dd2d6880220664feb0b4b2eb985fadb6ec7dc58c9334ea88ce599a9be7605' \
      '54a2d4b3b5d9f4'
    end
    let(:local_htlc_signature_3) do
      '304402200e362443f7af830b419771e8e1614fc391db3a4eb799989abfc5ab26' \
      'd6fcd032022039ab0cad1c14dfbe9446bf847965e56fe016e0cbcf719fd18c1b' \
      'fbf53ecbd9f9'
    end
    let(:remote_htlc_signature_3) do
      '3045022100d4e69d363de993684eae7b37853c40722a4c1b4a7b588ad7b5d8a9' \
      'b5006137a102207a069c628170ee34be5612747051bdcc087466dbaa68d5756e' \
      'a81c10155aef18'
    end
    let(:local_htlc_signature_4) do
      '304402202c3e14282b84b02705dfd00a6da396c9fe8a8bcb1d3fdb4b20a4feba' \
      '09440e8b02202b058b39aa9b0c865b22095edcd9ff1f71bbfe20aa4993755e54' \
      'd042755ed0d5'
    end
    let(:remote_htlc_signature_4) do
      '30450221008ec888e36e4a4b3dc2ed6b823319855b2ae03006ca6ae0d9aa7e24' \
      'bfc1d6f07102203b0f78885472a67ff4fe5916c0bb669487d659527509516fc3' \
      'a08e87a2cc0a7c'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8006d007000000000000220020403d3947' \
      '47cae42e98ff01734ad5c08f82ba123d3d9a620abda88989651e2ab5d0070000' \
      '00000000220020748eba944fedc8827f6b06bc44678f93c0f9e6078b35c6331e' \
      'd31e75f8ce0c2db80b000000000000220020c20b5d1f8584fd90443e7b7b7201' \
      '36174fa4b9333c261d04dbbd012635c0f419a00f0000000000002200208c48d1' \
      '5160397c9731df9bc3b236656efb6665fbfe92b4a6878e88a499f741c4c0c62d' \
      '0000000000160014ccf1af2f2aabee14bb40fa3851ab2301de84311077956a00' \
      '000000002200204adb4e2f00643db396dd120d4e7dc17625f5f2c11a40d857ac' \
      'cc862d6b7dd80e040047304402203ca8f31c6a47519f83255dc69f1894d9a6d7' \
      '476a19f498d31eaf0cd3a85eeb63022026fd92dc752b33905c4c838c528b692a' \
      '8ad4ced959990b5d5ee2ff940fa90eea01473044022001d55e488b8b035b2dd2' \
      '9d50b65b530923a416d47f377284145bc8767b1b6a75022019bb53ddfe1cefaf' \
      '156f924777eaaf8fdca1810695a7d0a247ad2afba8232eb401475221023da092' \
      'f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb21030e' \
      '9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c152' \
      'ae3e195220'
    end
    let(:expected_htlc_timeout_tx_2) do
      '02000000000101ca94a9ad516ebc0c4bdd7b6254871babfa978d5accafb55421' \
      '4137d398bfcf6a0000000000000000000175020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100d1cf354de41c1369336cf85b225ed033f1f8982a01be503668df756a' \
      '7e668b66022001254144fb4d0eecc61908fccc3388891ba17c5d7a1a8c62bdd3' \
      '07e5a513f99201473044022056eb1af429660e45a1b0b66568cb8c4a3aa7e4c9' \
      'c292d5d6c47f86ebf2c8838f022065c3ac4ebe980ca7a41148569be4ad8751b0' \
      'a724a41405697ec55035dae6640201008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b43e' \
      '1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_success_tx_1) do
      '02000000000101ca94a9ad516ebc0c4bdd7b6254871babfa978d5accafb55421' \
      '4137d398bfcf6a0100000000000000000122020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100d065569dcb94f090345402736385efeb8ea265131804beac06dd84d1' \
      '5dd2d6880220664feb0b4b2eb985fadb6ec7dc58c9334ea88ce599a9be760554' \
      'a2d4b3b5d9f401483045022100914bb232cd4b2690ee3d6cb8c3713c4ac9c4fb' \
      '925323068d8b07f67c8541f8d9022057152f5f1615b793d2d45aac7518989ae4' \
      'fe970f28b9b5c77504799d25433f7f0120010101010101010101010101010101' \
      '01010101010101010101010101010101018a76a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c8201208763a9144b6b2e5444c2639cc0' \
      'fb7bcea5afba3f3cdce23988527c21030d417a46946384f88d5f3337267c5e57' \
      '9765875dc4daca813e21734b140639e752ae677502f501b175ac686800000000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '02000000000101ca94a9ad516ebc0c4bdd7b6254871babfa978d5accafb55421' \
      '4137d398bfcf6a020000000000000000015d060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100d4e69d363de993684eae7b37853c40722a4c1b4a7b588ad7b5d8a9b5' \
      '006137a102207a069c628170ee34be5612747051bdcc087466dbaa68d5756ea8' \
      '1c10155aef180147304402200e362443f7af830b419771e8e1614fc391db3a4e' \
      'b799989abfc5ab26d6fcd032022039ab0cad1c14dfbe9446bf847965e56fe016' \
      'e0cbcf719fd18c1bfbf53ecbd9f901008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a48' \
      '6ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '02000000000101ca94a9ad516ebc0c4bdd7b6254871babfa978d5accafb55421' \
      '4137d398bfcf6a03000000000000000001f2090000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '450221008ec888e36e4a4b3dc2ed6b823319855b2ae03006ca6ae0d9aa7e24bf' \
      'c1d6f07102203b0f78885472a67ff4fe5916c0bb669487d659527509516fc3a0' \
      '8e87a2cc0a7c0147304402202c3e14282b84b02705dfd00a6da396c9fe8a8bcb' \
      '1d3fdb4b20a4feba09440e8b02202b058b39aa9b0c865b22095edcd9ff1f71bb' \
      'fe20aa4993755e54d042755ed0d5012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_success_tx_1.tx.to_payload.bth).to eq expected_htlc_success_tx_1 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with five outputs untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 2070
    # base commitment transaction fee = 2566
    # actual commitment transaction fee = 5566
    # HTLC 2 offered amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6985434 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 2070 }
    let(:local_sig) do
      '30440220443cb07f650aebbba14b8bc8d81e096712590f524c5991ac0ed3bbc8' \
      'fd3bd0c7022028a635f548e3ca64b19b69b1ea00f05b22752f91daf0b6dab78e' \
      '62ba52eb7fd0'
    end
    let(:remote_sig) do
      '3045022100f2377f7a67b7fc7f4e2c0c9e3a7de935c32417f5668eda31ea1db4' \
      '01b7dc53030220415fdbc8e91d0f735e70c21952342742e25249b0d062d43efb' \
      'fc564499f37526'
    end
    let(:local_htlc_signature_2) do
      '3045022100a0d043ed533e7fb1911e0553d31a8e2f3e6de19dbc035257f29d74' \
      '7c5e02f1f5022030cd38d8e84282175d49c1ebe0470db3ebd59768cf40780a78' \
      '4e248a43904fb8'
    end
    let(:remote_htlc_signature_2) do
      '3045022100eed143b1ee4bed5dc3cde40afa5db3e7354cbf9c44054b5f713f72' \
      '9356f08cf7022077161d171c2bbd9badf3c9934de65a4918de03bbac1450f715' \
      '275f75b103f891'
    end
    let(:local_htlc_signature_3) do
      '3045022100adb1d679f65f96178b59f23ed37d3b70443118f345224a07ecb043' \
      'eee2acc157022034d24524fe857144a3bcfff3065a9994d0a6ec5f11c681e494' \
      '31d573e242612d'
    end
    let(:remote_htlc_signature_3) do
      '3044022071e9357619fd8d29a411dc053b326a5224c5d11268070e88ecb981b1' \
      '74747c7a02202b763ae29a9d0732fa8836dd8597439460b50472183f420021b7' \
      '68981b4f7cf6'
    end
    let(:local_htlc_signature_4) do
      '304402200831422aa4e1ee6d55e0b894201770a8f8817a189356f2d70be76633' \
      'ffa6a6f602200dd1b84a4855dc6727dd46c98daae43dfc70889d1ba7ef008752' \
      '9a57c06e5e04'
    end
    let(:remote_htlc_signature_4) do
      '3045022100c9458a4d2cbb741705577deb0a890e5cb90ee141be0400d3162e53' \
      '3727c9cb2102206edcf765c5dc5e5f9b976ea8149bf8607b5a0efb30691138e1' \
      '231302b640d2a4'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8005d007000000000000220020403d3947' \
      '47cae42e98ff01734ad5c08f82ba123d3d9a620abda88989651e2ab5b80b0000' \
      '00000000220020c20b5d1f8584fd90443e7b7b720136174fa4b9333c261d04db' \
      'bd012635c0f419a00f0000000000002200208c48d15160397c9731df9bc3b236' \
      '656efb6665fbfe92b4a6878e88a499f741c4c0c62d0000000000160014ccf1af' \
      '2f2aabee14bb40fa3851ab2301de843110da966a00000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e04004730' \
      '440220443cb07f650aebbba14b8bc8d81e096712590f524c5991ac0ed3bbc8fd' \
      '3bd0c7022028a635f548e3ca64b19b69b1ea00f05b22752f91daf0b6dab78e62' \
      'ba52eb7fd001483045022100f2377f7a67b7fc7f4e2c0c9e3a7de935c32417f5' \
      '668eda31ea1db401b7dc53030220415fdbc8e91d0f735e70c21952342742e252' \
      '49b0d062d43efbfc564499f3752601475221023da092f6980e58d2c037173180' \
      'e9a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d' \
      '66d5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_timeout_tx_2) do
      '0200000000010140a83ce364747ff277f4d7595d8d15f708418798922c40bc2b' \
      '056aca5485a2180000000000000000000174020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100eed143b1ee4bed5dc3cde40afa5db3e7354cbf9c44054b5f713f7293' \
      '56f08cf7022077161d171c2bbd9badf3c9934de65a4918de03bbac1450f71527' \
      '5f75b103f89101483045022100a0d043ed533e7fb1911e0553d31a8e2f3e6de1' \
      '9dbc035257f29d747c5e02f1f5022030cd38d8e84282175d49c1ebe0470db3eb' \
      'd59768cf40780a784e248a43904fb801008576a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a469463' \
      '84f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b4' \
      '3e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '0200000000010140a83ce364747ff277f4d7595d8d15f708418798922c40bc2b' \
      '056aca5485a218010000000000000000015c060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '44022071e9357619fd8d29a411dc053b326a5224c5d11268070e88ecb981b174' \
      '747c7a02202b763ae29a9d0732fa8836dd8597439460b50472183f420021b768' \
      '981b4f7cf601483045022100adb1d679f65f96178b59f23ed37d3b70443118f3' \
      '45224a07ecb043eee2acc157022034d24524fe857144a3bcfff3065a9994d0a6' \
      'ec5f11c681e49431d573e242612d01008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a48' \
      '6ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '0200000000010140a83ce364747ff277f4d7595d8d15f708418798922c40bc2b' \
      '056aca5485a21802000000000000000001f1090000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100c9458a4d2cbb741705577deb0a890e5cb90ee141be0400d3162e5337' \
      '27c9cb2102206edcf765c5dc5e5f9b976ea8149bf8607b5a0efb30691138e123' \
      '1302b640d2a40147304402200831422aa4e1ee6d55e0b894201770a8f8817a18' \
      '9356f2d70be76633ffa6a6f602200dd1b84a4855dc6727dd46c98daae43dfc70' \
      '889d1ba7ef0087529a57c06e5e04012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with five outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 2194
    # base commitment transaction fee = 2720
    # actual commitment transaction fee = 5720
    # HTLC 2 offered amount 2000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a914b43e1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6985280 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc2, htlc3, htlc4] }
    let(:local_feerate_per_kw) { 2194 }
    let(:local_sig) do
      '304402203b1b010c109c2ecbe7feb2d259b9c4126bd5dc99ee693c422ec0a578' \
      '1fe161ba0220571fe4e2c649dea9c7aaf7e49b382962f6a3494963c97d80fef9' \
      'a430ca3f7061'
    end
    let(:remote_sig) do
      '3045022100d33c4e541aa1d255d41ea9a3b443b3b822ad8f7f86862638aac1f6' \
      '9f8f760577022007e2a18e6931ce3d3a804b1c78eda1de17dbe1fb7a95488c9a' \
      '4ec86203953348'
    end
    let(:local_htlc_signature_2) do
      '3044022004ad5f04ae69c71b3b141d4db9d0d4c38d84009fb3cfeeae6efdad41' \
      '4487a9a0022042d3fe1388c1ff517d1da7fb4025663d372c14728ed52dc88608' \
      '363450ff6a2f'
    end
    let(:remote_htlc_signature_2) do
      '30450221009ed2f0a67f99e29c3c8cf45c08207b765980697781bb727fe0b141' \
      '6de0e7622902206052684229bc171419ed290f4b615c943f819c0262414e43c5' \
      'b91dcf72ddcf44'
    end
    let(:local_htlc_signature_3) do
      '304402201707050c870c1f77cc3ed58d6d71bf281de239e9eabd8ef0955bad0d' \
      '7fe38dcc02204d36d80d0019b3a71e646a08fa4a5607761d341ae8be371946eb' \
      'e437c289c915'
    end
    let(:remote_htlc_signature_3) do
      '30440220155d3b90c67c33a8321996a9be5b82431b0c126613be751d400669da' \
      '9d5c696702204318448bcd48824439d2c6a70be6e5747446be47ff45977cf416' \
      '72bdc9b6b12d'
    end
    let(:local_htlc_signature_4) do
      '3045022100ff200bc934ab26ce9a559e998ceb0aee53bc40368e114ab9d3054d' \
      '9960546e2802202496856ca163ac12c143110b6b3ac9d598df7254f2e17b3b94' \
      'c3ab5301f4c3b0'
    end
    let(:remote_htlc_signature_4) do
      '3045022100a12a9a473ece548584aabdd051779025a5ed4077c4b7aa376ec7a0' \
      'b1645e5a48022039490b333f53b5b3e2ddde1d809e492cba2b3e5fc3a436cd3f' \
      'fb4cd3d500fa5a'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8005d007000000000000220020403d3947' \
      '47cae42e98ff01734ad5c08f82ba123d3d9a620abda88989651e2ab5b80b0000' \
      '00000000220020c20b5d1f8584fd90443e7b7b720136174fa4b9333c261d04db' \
      'bd012635c0f419a00f0000000000002200208c48d15160397c9731df9bc3b236' \
      '656efb6665fbfe92b4a6878e88a499f741c4c0c62d0000000000160014ccf1af' \
      '2f2aabee14bb40fa3851ab2301de84311040966a00000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e04004730' \
      '4402203b1b010c109c2ecbe7feb2d259b9c4126bd5dc99ee693c422ec0a5781f' \
      'e161ba0220571fe4e2c649dea9c7aaf7e49b382962f6a3494963c97d80fef9a4' \
      '30ca3f706101483045022100d33c4e541aa1d255d41ea9a3b443b3b822ad8f7f' \
      '86862638aac1f69f8f760577022007e2a18e6931ce3d3a804b1c78eda1de17db' \
      'e1fb7a95488c9a4ec8620395334801475221023da092f6980e58d2c037173180' \
      'e9a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d' \
      '66d5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_timeout_tx_2) do
      '02000000000101fb824d4e4dafc0f567789dee3a6bce8d411fe80f5563d8cdfd' \
      'cc7d7e4447d43a0000000000000000000122020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '450221009ed2f0a67f99e29c3c8cf45c08207b765980697781bb727fe0b1416d' \
      'e0e7622902206052684229bc171419ed290f4b615c943f819c0262414e43c5b9' \
      '1dcf72ddcf4401473044022004ad5f04ae69c71b3b141d4db9d0d4c38d84009f' \
      'b3cfeeae6efdad414487a9a0022042d3fe1388c1ff517d1da7fb4025663d372c' \
      '14728ed52dc88608363450ff6a2f01008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a914b43e' \
      '1b38138a41b37f7cd9a1d274bc63e3a9b5d188ac6868f6010000'
    end
    let(:expected_htlc_timeout_tx_3) do
      '02000000000101fb824d4e4dafc0f567789dee3a6bce8d411fe80f5563d8cdfd' \
      'cc7d7e4447d43a010000000000000000010a060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '440220155d3b90c67c33a8321996a9be5b82431b0c126613be751d400669da9d' \
      '5c696702204318448bcd48824439d2c6a70be6e5747446be47ff45977cf41672' \
      'bdc9b6b12d0147304402201707050c870c1f77cc3ed58d6d71bf281de239e9ea' \
      'bd8ef0955bad0d7fe38dcc02204d36d80d0019b3a71e646a08fa4a5607761d34' \
      '1ae8be371946ebe437c289c91501008576a91414011f7254d96b819c76986c27' \
      '7d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a2184' \
      'd88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f8' \
      '8d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a486f' \
      'f2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '02000000000101fb824d4e4dafc0f567789dee3a6bce8d411fe80f5563d8cdfd' \
      'cc7d7e4447d43a020000000000000000019a090000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100a12a9a473ece548584aabdd051779025a5ed4077c4b7aa376ec7a0b1' \
      '645e5a48022039490b333f53b5b3e2ddde1d809e492cba2b3e5fc3a436cd3ffb' \
      '4cd3d500fa5a01483045022100ff200bc934ab26ce9a559e998ceb0aee53bc40' \
      '368e114ab9d3054d9960546e2802202496856ca163ac12c143110b6b3ac9d598' \
      'df7254f2e17b3b94c3ab5301f4c3b00120040404040404040404040404040404' \
      '04040404040404040404040404040404048a76a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d' \
      '3d23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e57' \
      '9765875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_2.tx.to_payload.bth).to eq expected_htlc_timeout_tx_2 }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with four outputs untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 2195
    # base commitment transaction fee = 2344
    # actual commitment transaction fee = 7344
    # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc
    # 726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca813
    # e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122c
    # c726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d41
    # 7a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # to_local amount 6985656 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b275
    # 2103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)

    let(:htlcs) { Set[htlc3, htlc4] }
    let(:local_feerate_per_kw) { 2195 }
    let(:local_sig) do
      '304402203b12d44254244b8ff3bb4129b0920fd45120ab42f553d9976394b099' \
      'd500c99e02205e95bb7a3164852ef0c48f9e0eaf145218f8e2c41251b231f03c' \
      'bdc4f29a5429'
    end
    let(:remote_sig) do
      '304402205e2f76d4657fb732c0dfc820a18a7301e368f5799e06b78280076337' \
      '41bda6df0220458009ae59d0c6246065c419359e05eb2a4b4ef4a1b310cc912d' \
      'b44eb7924298'
    end
    let(:local_htlc_signature_3) do
      '3045022100be6ae1977fd7b630a53623f3f25c542317ccfc2b971782802a4f1e' \
      'f538eb22b402207edc4d0408f8f38fd3c7365d1cfc26511b7cd2d4fecd8b005f' \
      'ba3cd5bc704390'
    end
    let(:remote_htlc_signature_3) do
      '3045022100a8a78fa1016a5c5c3704f2e8908715a3cef66723fb95f3132ec4d2' \
      'd05cd84fb4022025ac49287b0861ec21932405f5600cbce94313dbde0e6c5d5a' \
      'f1b3366d8afbfc'
    end
    let(:local_htlc_signature_4) do
      '30440220665b9cb4a978c09d1ca8977a534999bc8a49da624d0c5439451dd69c' \
      'de1a003d022070eae0620f01f3c1bd029cc1488da13fb40fdab76f396ccd3354' \
      '79a11c5276d8'
    end
    let(:remote_htlc_signature_4) do
      '3045022100e769cb156aa2f7515d126cef7a69968629620ce82afcaa9e210969' \
      'de6850df4602200b16b3f3486a229a48aadde520dbee31ae340dbadaffae74fb' \
      'b56681fef27b92'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8004b80b000000000000220020c20b5d1f' \
      '8584fd90443e7b7b720136174fa4b9333c261d04dbbd012635c0f419a00f0000' \
      '000000002200208c48d15160397c9731df9bc3b236656efb6665fbfe92b4a687' \
      '8e88a499f741c4c0c62d0000000000160014ccf1af2f2aabee14bb40fa3851ab' \
      '2301de843110b8976a00000000002200204adb4e2f00643db396dd120d4e7dc1' \
      '7625f5f2c11a40d857accc862d6b7dd80e040047304402203b12d44254244b8f' \
      'f3bb4129b0920fd45120ab42f553d9976394b099d500c99e02205e95bb7a3164' \
      '852ef0c48f9e0eaf145218f8e2c41251b231f03cbdc4f29a5429014730440220' \
      '5e2f76d4657fb732c0dfc820a18a7301e368f5799e06b7828007633741bda6df' \
      '0220458009ae59d0c6246065c419359e05eb2a4b4ef4a1b310cc912db44eb792' \
      '429801475221023da092f6980e58d2c037173180e9a465476026ee50f9669596' \
      '3e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a1' \
      '32cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_timeout_tx_3) do
      '020000000001014e16c488fa158431c1a82e8f661240ec0a71ba0ce92f2721a6' \
      '538c510226ad5c0000000000000000000109060000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100a8a78fa1016a5c5c3704f2e8908715a3cef66723fb95f3132ec4d2d0' \
      '5cd84fb4022025ac49287b0861ec21932405f5600cbce94313dbde0e6c5d5af1' \
      'b3366d8afbfc01483045022100be6ae1977fd7b630a53623f3f25c542317ccfc' \
      '2b971782802a4f1ef538eb22b402207edc4d0408f8f38fd3c7365d1cfc26511b' \
      '7cd2d4fecd8b005fba3cd5bc70439001008576a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a469463' \
      '84f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a' \
      '486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '020000000001014e16c488fa158431c1a82e8f661240ec0a71ba0ce92f2721a6' \
      '538c510226ad5c0100000000000000000199090000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100e769cb156aa2f7515d126cef7a69968629620ce82afcaa9e210969de' \
      '6850df4602200b16b3f3486a229a48aadde520dbee31ae340dbadaffae74fbb5' \
      '6681fef27b92014730440220665b9cb4a978c09d1ca8977a534999bc8a49da62' \
      '4d0c5439451dd69cde1a003d022070eae0620f01f3c1bd029cc1488da13fb40f' \
      'dab76f396ccd335479a11c5276d8012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with four outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 3702
    # # base commitment transaction fee = 3953
    # # actual commitment transaction fee = 8953
    # # HTLC 3 offered amount 3000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a8122
    # cc726e9dded053a2184d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384f88d5f3337267c5e579765875dc4daca8
    # 13e21734b140639e752ae67a9148a486ff2e31d6158bf39e2608864d63fefd09d5b88ac6868
    # # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a812
    # 2cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d
    # 417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # # to_local amount 6984047 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b2
    # 752103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 3045022100c1a3b0b60ca092ed5080121f26a74a20cec6bdee3f8e47bae973fcdceb3eda5502207d467a9873c939bf3
    # aa758014ae67295fedbca52412633f7e5b2670fc7c381c1
    # # local_signature = 304402200e930a43c7951162dc15a2b7344f48091c74c70f7024e7116e900d8bcfba861c022066fa6cbda3929e21da
    # a2e7e16a4b948db7e8919ef978402360d1095ffdaff7b0

    let(:htlcs) { Set[htlc3, htlc4] }
    let(:local_feerate_per_kw) { 3702 }
    let(:local_sig) do
      '304402200e930a43c7951162dc15a2b7344f48091c74c70f7024e7116e900d8b' \
      'cfba861c022066fa6cbda3929e21daa2e7e16a4b948db7e8919ef978402360d1' \
      '095ffdaff7b0'
    end
    let(:remote_sig) do
      '3045022100c1a3b0b60ca092ed5080121f26a74a20cec6bdee3f8e47bae973fc' \
      'dceb3eda5502207d467a9873c939bf3aa758014ae67295fedbca52412633f7e5' \
      'b2670fc7c381c1'
    end
    let(:local_htlc_signature_3) do
      '304402202765b9c9ece4f127fa5407faf66da4c5ce2719cdbe47cd3175fc7d48' \
      'b482e43d02205605125925e07bad1e41c618a4b434d72c88a164981c4b8af5ea' \
      'f4ee9142ec3a'
    end
    let(:remote_htlc_signature_3) do
      '3045022100dfb73b4fe961b31a859b2bb1f4f15cabab9265016dd0272323dc6a' \
      '9e85885c54022059a7b87c02861ee70662907f25ce11597d7b68d3399443a831' \
      'ae40e777b76bdb'
    end
    let(:local_htlc_signature_4) do
      '30440220048a41c660c4841693de037d00a407810389f4574b3286afb7bc392a' \
      '438fa3f802200401d71fa87c64fe621b49ac07e3bf85157ac680acb977124da2' \
      '8652cc7f1a5c'
    end
    let(:remote_htlc_signature_4) do
      '3045022100ea9dc2a7c3c3640334dab733bb4e036e32a3106dc707b24227874f' \
      'a4f7da746802204d672f7ac0fe765931a8df10b81e53a3242dd32bd9dc9331eb' \
      '4a596da87954e9'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8004b80b000000000000220020c20b5d1f' \
      '8584fd90443e7b7b720136174fa4b9333c261d04dbbd012635c0f419a00f0000' \
      '000000002200208c48d15160397c9731df9bc3b236656efb6665fbfe92b4a687' \
      '8e88a499f741c4c0c62d0000000000160014ccf1af2f2aabee14bb40fa3851ab' \
      '2301de8431106f916a00000000002200204adb4e2f00643db396dd120d4e7dc1' \
      '7625f5f2c11a40d857accc862d6b7dd80e040047304402200e930a43c7951162' \
      'dc15a2b7344f48091c74c70f7024e7116e900d8bcfba861c022066fa6cbda392' \
      '9e21daa2e7e16a4b948db7e8919ef978402360d1095ffdaff7b0014830450221' \
      '00c1a3b0b60ca092ed5080121f26a74a20cec6bdee3f8e47bae973fcdceb3eda' \
      '5502207d467a9873c939bf3aa758014ae67295fedbca52412633f7e5b2670fc7' \
      'c381c101475221023da092f6980e58d2c037173180e9a465476026ee50f96695' \
      '963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385' \
      'a132cec6d3c39fa711c152ae3e195220'
    end
    let(:expected_htlc_timeout_tx_3) do
      '02000000000101b8de11eb51c22498fe39722c7227b6e55ff1a94146cf638458' \
      'cb9bc6a060d3a30000000000000000000122020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100dfb73b4fe961b31a859b2bb1f4f15cabab9265016dd0272323dc6a9e' \
      '85885c54022059a7b87c02861ee70662907f25ce11597d7b68d3399443a831ae' \
      '40e777b76bdb0147304402202765b9c9ece4f127fa5407faf66da4c5ce2719cd' \
      'be47cd3175fc7d48b482e43d02205605125925e07bad1e41c618a4b434d72c88' \
      'a164981c4b8af5eaf4ee9142ec3a01008576a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c820120876475527c21030d417a46946384' \
      'f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae67a9148a48' \
      '6ff2e31d6158bf39e2608864d63fefd09d5b88ac6868f7010000'
    end
    let(:expected_htlc_success_tx_4) do
      '02000000000101b8de11eb51c22498fe39722c7227b6e55ff1a94146cf638458' \
      'cb9bc6a060d3a30100000000000000000176050000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100ea9dc2a7c3c3640334dab733bb4e036e32a3106dc707b24227874fa4' \
      'f7da746802204d672f7ac0fe765931a8df10b81e53a3242dd32bd9dc9331eb4a' \
      '596da87954e9014730440220048a41c660c4841693de037d00a407810389f457' \
      '4b3286afb7bc392a438fa3f802200401d71fa87c64fe621b49ac07e3bf85157a' \
      'c680acb977124da28652cc7f1a5c012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_timeout_tx_3.tx.to_payload.bth).to eq expected_htlc_timeout_tx_3 }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with three outputs untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 3703
    # # base commitment transaction fee = 3317
    # # actual commitment transaction fee = 11317
    # # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a812
    # 2cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d
    # 417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # # to_local amount 6984683 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b2
    # 752103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 30450221008b7c191dd46893b67b628e618d2dc8e81169d38bade310181ab77d7c94c6675e02203b4dd131fd7c9deb2
    # 99560983dcdc485545c98f989f7ae8180c28289f9e6bdb0
    # # local_signature = 3044022047305531dd44391dce03ae20f8735005c615eb077a974edb0059ea1a311857d602202e0ed6972fbdd1e8cb
    # 542b06e0929bc41b2ddf236e04cb75edd56151f4197506

    let(:htlcs) { Set[htlc4] }
    let(:local_feerate_per_kw) { 3703 }
    let(:local_sig) do
      '3044022047305531dd44391dce03ae20f8735005c615eb077a974edb0059ea1a' \
      '311857d602202e0ed6972fbdd1e8cb542b06e0929bc41b2ddf236e04cb75edd5' \
      '6151f4197506'
    end
    let(:remote_sig) do
      '30450221008b7c191dd46893b67b628e618d2dc8e81169d38bade310181ab77d' \
      '7c94c6675e02203b4dd131fd7c9deb299560983dcdc485545c98f989f7ae8180' \
      'c28289f9e6bdb0'
    end
    let(:local_htlc_signature_4) do
      '3045022100b94d931a811b32eeb885c28ddcf999ae1981893b21dd1329929543' \
      'fe87ce793002206370107fdd151c5f2384f9ceb71b3107c69c74c8ed5a28a94a' \
      '4ab2d27d3b0724'
    end
    let(:remote_htlc_signature_4) do
      '3044022044f65cf833afdcb9d18795ca93f7230005777662539815b8a601eeb3' \
      'e57129a902206a4bf3e53392affbba52640627defa8dc8af61c958c9e827b279' \
      '8ab45828abdd'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8003a00f0000000000002200208c48d151' \
      '60397c9731df9bc3b236656efb6665fbfe92b4a6878e88a499f741c4c0c62d00' \
      '00000000160014ccf1af2f2aabee14bb40fa3851ab2301de843110eb936a0000' \
      '0000002200204adb4e2f00643db396dd120d4e7dc17625f5f2c11a40d857accc' \
      '862d6b7dd80e0400473044022047305531dd44391dce03ae20f8735005c615eb' \
      '077a974edb0059ea1a311857d602202e0ed6972fbdd1e8cb542b06e0929bc41b' \
      '2ddf236e04cb75edd56151f4197506014830450221008b7c191dd46893b67b62' \
      '8e618d2dc8e81169d38bade310181ab77d7c94c6675e02203b4dd131fd7c9deb' \
      '299560983dcdc485545c98f989f7ae8180c28289f9e6bdb001475221023da092' \
      'f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb21030e' \
      '9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c152' \
      'ae3e195220'
    end
    let(:expected_htlc_success_tx_4) do
      '020000000001011c076aa7fb3d7460d10df69432c904227ea84bbf3134d4ceee' \
      '5fb0f135ef206d0000000000000000000175050000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004730' \
      '44022044f65cf833afdcb9d18795ca93f7230005777662539815b8a601eeb3e5' \
      '7129a902206a4bf3e53392affbba52640627defa8dc8af61c958c9e827b2798a' \
      'b45828abdd01483045022100b94d931a811b32eeb885c28ddcf999ae1981893b' \
      '21dd1329929543fe87ce793002206370107fdd151c5f2384f9ceb71b3107c69c' \
      '74c8ed5a28a94a4ab2d27d3b0724012004040404040404040404040404040404' \
      '040404040404040404040404040404048a76a91414011f7254d96b819c76986c' \
      '277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a21' \
      '84d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d' \
      '23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e5797' \
      '65875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with three outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 4914
    # # base commitment transaction fee = 4402
    # # actual commitment transaction fee = 12402
    # # HTLC 4 received amount 4000 wscript 76a91414011f7254d96b819c76986c277d115efce6f7b58763ac67210394854aa6eab5b2a812
    # 2cc726e9dded053a2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d3d23e28d3b0a9d1227434288527c21030d
    # 417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e752ae677502f801b175ac6868
    # # to_local amount 6983598 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b2
    # 752103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 304402206d6cb93969d39177a09d5d45b583f34966195b77c7e585cf47ac5cce0c90cefb022031d71ae4e33a4e80df7
    # f981d696fbdee517337806a3c7138b7491e2cbb077a0e
    # # local_signature = 304402206a2679efa3c7aaffd2a447fd0df7aba8792858b589750f6a1203f9259173198a022008d52a0e77a99ab533
    # c36206cb15ad7aeb2aa72b93d4b571e728cb5ec2f6fe26

    let(:htlcs) { Set[htlc4] }
    let(:local_feerate_per_kw) { 4914 }
    let(:local_sig) do
      '304402206a2679efa3c7aaffd2a447fd0df7aba8792858b589750f6a1203f925' \
      '9173198a022008d52a0e77a99ab533c36206cb15ad7aeb2aa72b93d4b571e728' \
      'cb5ec2f6fe26'
    end
    let(:remote_sig) do
      '304402206d6cb93969d39177a09d5d45b583f34966195b77c7e585cf47ac5cce' \
      '0c90cefb022031d71ae4e33a4e80df7f981d696fbdee517337806a3c7138b749' \
      '1e2cbb077a0e'
    end
    let(:local_htlc_signature_4) do
      '304502210086e76b460ddd3cea10525fba298405d3fe11383e56966a50918113' \
      '68362f689a02200f72ee75657915e0ede89c28709acd113ede9e1b7be520e3bc' \
      '5cda425ecd6e68'
    end
    let(:remote_htlc_signature_4) do
      '3045022100fcb38506bfa11c02874092a843d0cc0a8613c23b639832564a5f69' \
      '020cb0f6ba02206508b9e91eaa001425c190c68ee5f887e1ad5b1b314002e74d' \
      'b9dbd9e42dbecf'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8003a00f0000000000002200208c48d151' \
      '60397c9731df9bc3b236656efb6665fbfe92b4a6878e88a499f741c4c0c62d00' \
      '00000000160014ccf1af2f2aabee14bb40fa3851ab2301de843110ae8f6a0000' \
      '0000002200204adb4e2f00643db396dd120d4e7dc17625f5f2c11a40d857accc' \
      '862d6b7dd80e040047304402206a2679efa3c7aaffd2a447fd0df7aba8792858' \
      'b589750f6a1203f9259173198a022008d52a0e77a99ab533c36206cb15ad7aeb' \
      '2aa72b93d4b571e728cb5ec2f6fe260147304402206d6cb93969d39177a09d5d' \
      '45b583f34966195b77c7e585cf47ac5cce0c90cefb022031d71ae4e33a4e80df' \
      '7f981d696fbdee517337806a3c7138b7491e2cbb077a0e01475221023da092f6' \
      '980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb21030e9f' \
      '7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c152ae' \
      '3e195220'
    end
    let(:expected_htlc_success_tx_4) do
      '0200000000010110a3fdcbcd5db477cd3ad465e7f501ffa8c437e8301f00a606' \
      '1138590add757f0000000000000000000122020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e05004830' \
      '45022100fcb38506bfa11c02874092a843d0cc0a8613c23b639832564a5f6902' \
      '0cb0f6ba02206508b9e91eaa001425c190c68ee5f887e1ad5b1b314002e74db9' \
      'dbd9e42dbecf0148304502210086e76b460ddd3cea10525fba298405d3fe1138' \
      '3e56966a5091811368362f689a02200f72ee75657915e0ede89c28709acd113e' \
      'de9e1b7be520e3bc5cda425ecd6e680120040404040404040404040404040404' \
      '04040404040404040404040404040404048a76a91414011f7254d96b819c7698' \
      '6c277d115efce6f7b58763ac67210394854aa6eab5b2a8122cc726e9dded053a' \
      '2184d88256816826d6231c068d4a5b7c8201208763a91418bc1a114ccf9c052d' \
      '3d23e28d3b0a9d1227434288527c21030d417a46946384f88d5f3337267c5e57' \
      '9765875dc4daca813e21734b140639e752ae677502f801b175ac686800000000'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
    it { expect(htlc_success_tx_4.tx.to_payload.bth).to eq expected_htlc_success_tx_4 }
  end

  describe 'commitment tx with two outputs untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 4915
    # # base commitment transaction fee = 3558
    # # actual commitment transaction fee = 15558
    # # to_local amount 6984442 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b2
    # 752103fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 304402200769ba89c7330dfa4feba447b6e322305f12ac7dac70ec6ba997ed7c1b598d0802204fe8d337e7fee781f9b
    # 7b1a06e580b22f4f79d740059560191d7db53f8765552
    # # local_signature = 3045022100a012691ba6cea2f73fa8bac37750477e66363c6d28813b0bb6da77c8eb3fb0270220365e99c51304b0b1
    # a6ab9ea1c8500db186693e39ec1ad5743ee231b0138384b9

    let(:htlcs) { Set[] }
    let(:local_feerate_per_kw) { 4915 }
    let(:local_sig) do
      '3045022100a012691ba6cea2f73fa8bac37750477e66363c6d28813b0bb6da77' \
      'c8eb3fb0270220365e99c51304b0b1a6ab9ea1c8500db186693e39ec1ad5743e' \
      'e231b0138384b9'
    end
    let(:remote_sig) do
      '304402200769ba89c7330dfa4feba447b6e322305f12ac7dac70ec6ba997ed7c' \
      '1b598d0802204fe8d337e7fee781f9b7b1a06e580b22f4f79d740059560191d7' \
      'db53f8765552'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8002c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de843110fa926a00000000002200204adb4e2f00' \
      '643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80e0400483045' \
      '022100a012691ba6cea2f73fa8bac37750477e66363c6d28813b0bb6da77c8eb' \
      '3fb0270220365e99c51304b0b1a6ab9ea1c8500db186693e39ec1ad5743ee231' \
      'b0138384b90147304402200769ba89c7330dfa4feba447b6e322305f12ac7dac' \
      '70ec6ba997ed7c1b598d0802204fe8d337e7fee781f9b7b1a06e580b22f4f79d' \
      '740059560191d7db53f876555201475221023da092f6980e58d2c037173180e9' \
      'a465476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66' \
      'd5ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
  end

  describe 'commitment tx with two outputs untrimmed (maximum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 9651180
    # # base commitment transaction fee = 6987454
    # # actual commitment transaction fee = 6999454
    # # to_local amount 546 wscript 63210212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b1967029000b27521
    # 03fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c68ac
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 3044022037f83ff00c8e5fb18ae1f918ffc24e54581775a20ff1ae719297ef066c71caa9022039c529cccd89ff6c5ed
    # 1db799614533844bd6d101da503761c45c713996e3bbd
    # # local_signature = 30440220514f977bf7edc442de8ce43ace9686e5ebdc0f893033f13e40fb46c8b8c6e1f90220188006227d175f5c35
    # da0b092c57bea82537aed89f7778204dc5bacf4f29f2b9

    let(:htlcs) { Set[] }
    let(:local_feerate_per_kw) { 9_651_180 }
    let(:local_sig) do
      '30440220514f977bf7edc442de8ce43ace9686e5ebdc0f893033f13e40fb46c8' \
      'b8c6e1f90220188006227d175f5c35da0b092c57bea82537aed89f7778204dc5' \
      'bacf4f29f2b9'
    end
    let(:remote_sig) do
      '3044022037f83ff00c8e5fb18ae1f918ffc24e54581775a20ff1ae719297ef06' \
      '6c71caa9022039c529cccd89ff6c5ed1db799614533844bd6d101da503761c45' \
      'c713996e3bbd'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b800222020000000000002200204adb4e2f' \
      '00643db396dd120d4e7dc17625f5f2c11a40d857accc862d6b7dd80ec0c62d00' \
      '00000000160014ccf1af2f2aabee14bb40fa3851ab2301de8431100400473044' \
      '0220514f977bf7edc442de8ce43ace9686e5ebdc0f893033f13e40fb46c8b8c6' \
      'e1f90220188006227d175f5c35da0b092c57bea82537aed89f7778204dc5bacf' \
      '4f29f2b901473044022037f83ff00c8e5fb18ae1f918ffc24e54581775a20ff1' \
      'ae719297ef066c71caa9022039c529cccd89ff6c5ed1db799614533844bd6d10' \
      '1da503761c45c713996e3bbd01475221023da092f6980e58d2c037173180e9a4' \
      '65476026ee50f96695963e8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5' \
      'ce21ce504c0acf6385a132cec6d3c39fa711c152ae3e195220'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
  end

  describe 'commitment tx with one output untrimmed (minimum feerate)' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 9651181
    # # base commitment transaction fee = 6987455
    # # actual commitment transaction fee = 7000000
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 3044022064901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f88ef0731d02206d1dfa227527b4df44a
    # 07599289e207d6fd9cca60c0365682dcd3deaf739567e
    # # local_signature = 3044022031a82b51bd014915fe68928d1abf4b9885353fb896cac10c3fdd88d7f9c7f2e00220716bda819641d2c63e
    # 65d3549b6120112e1aeaf1742eed94a471488e79e206b1

    let(:htlcs) { Set[] }
    let(:local_feerate_per_kw) { 9_651_181 }
    let(:local_sig) do
      '3044022031a82b51bd014915fe68928d1abf4b9885353fb896cac10c3fdd88d7' \
      'f9c7f2e00220716bda819641d2c63e65d3549b6120112e1aeaf1742eed94a471' \
      '488e79e206b1'
    end
    let(:remote_sig) do
      '3044022064901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f8' \
      '8ef0731d02206d1dfa227527b4df44a07599289e207d6fd9cca60c0365682dcd' \
      '3deaf739567e'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8001c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de8431100400473044022031a82b51bd014915fe' \
      '68928d1abf4b9885353fb896cac10c3fdd88d7f9c7f2e00220716bda819641d2' \
      'c63e65d3549b6120112e1aeaf1742eed94a471488e79e206b101473044022064' \
      '901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f88ef0731d02' \
      '206d1dfa227527b4df44a07599289e207d6fd9cca60c0365682dcd3deaf73956' \
      '7e01475221023da092f6980e58d2c037173180e9a465476026ee50f96695963e' \
      '8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132' \
      'cec6d3c39fa711c152ae3e195220'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
  end

  describe 'commitment tx with fee greater than funder amount' do
    # to_local_msat: 6988000000
    # to_remote_msat: 3000000000
    # local_feerate_per_kw: 9651936
    # # base commitment transaction fee = 6988001
    # # actual commitment transaction fee = 7000000
    # # to_remote amount 3000000 P2WPKH(0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b)
    # remote_signature = 3044022064901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f88ef0731d02206d1dfa227527b4df44a
    # 07599289e207d6fd9cca60c0365682dcd3deaf739567e
    # # local_signature = 3044022031a82b51bd014915fe68928d1abf4b9885353fb896cac10c3fdd88d7f9c7f2e00220716bda819641d2c63e
    # 65d3549b6120112e1aeaf1742eed94a471488e79e206b1
    let(:htlcs) { Set[] }
    let(:local_feerate_per_kw) { 9_651_936 }
    let(:local_sig) do
      '3044022031a82b51bd014915fe68928d1abf4b9885353fb896cac10c3fdd88d7' \
      'f9c7f2e00220716bda819641d2c63e65d3549b6120112e1aeaf1742eed94a471' \
      '488e79e206b1'
    end
    let(:remote_sig) do
      '3044022064901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f8' \
      '8ef0731d02206d1dfa227527b4df44a07599289e207d6fd9cca60c0365682dcd' \
      '3deaf739567e'
    end
    let(:expected_commitment_tx) do
      '02000000000101bef67e4e2fb9ddeeb3461973cd4c62abb35050b1add772995b' \
      '820b584a488489000000000038b02b8001c0c62d0000000000160014ccf1af2f' \
      '2aabee14bb40fa3851ab2301de8431100400473044022031a82b51bd014915fe' \
      '68928d1abf4b9885353fb896cac10c3fdd88d7f9c7f2e00220716bda819641d2' \
      'c63e65d3549b6120112e1aeaf1742eed94a471488e79e206b101473044022064' \
      '901950be922e62cbe3f2ab93de2b99f37cff9fc473e73e394b27f88ef0731d02' \
      '206d1dfa227527b4df44a07599289e207d6fd9cca60c0365682dcd3deaf73956' \
      '7e01475221023da092f6980e58d2c037173180e9a465476026ee50f96695963e' \
      '8efe436f54eb21030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132' \
      'cec6d3c39fa711c152ae3e195220'
    end

    it { expect(commitment_tx.to_payload.bth).to eq expected_commitment_tx }
  end
end
