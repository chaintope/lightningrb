# frozen_string_literal: true

FactoryBot.define do
  factory(:key, class: 'Bitcoin::Key') do
    priv_key nil
    pubkey nil
    initialize_with { new(priv_key: priv_key, pubkey: pubkey) }

    trait(:local_funding_privkey) do
      priv_key '30ff4956bbdd3222d44cc5e8a1261dab1e07957bdac5ae88fe3261ef321f3749'
    end

    trait(:local_funding_pubkey) do
      pubkey '023da092f6980e58d2c037173180e9a465476026ee50f96695963e8efe436f54eb'
    end

    trait(:remote_funding_privkey) do
      priv_key '1552dfba4f6cf29a62a0af13c8d6981d36d0ef8d61ba10fb0fe90da7634d7e13'
    end

    trait(:remote_funding_pubkey) do
      pubkey '030e9f7b623d2ccc7c9bd44d66d5ce21ce504c0acf6385a132cec6d3c39fa711c1'
    end

    trait(:local_privkey) do
      priv_key 'bb13b121cdc357cd2e608b0aea294afca36e2b34cf958e2e6451a2f274694491'
    end

    trait(:local_pubkey) do
      pubkey '030d417a46946384f88d5f3337267c5e579765875dc4daca813e21734b140639e7'
    end

    trait(:remote_pubkey) do
      pubkey '0394854aa6eab5b2a8122cc726e9dded053a2184d88256816826d6231c068d4a5b'
    end

    trait(:local_delayed_pubkey) do
      pubkey '03fd5960528dc152014952efdb702a88f71e3c1653b2314431701ec77e57fde83c'
    end

    trait(:local_revocation_pubkey) do
      pubkey '0212a140cd0c6539d07cd08dfe09984dec3251ea808b892efeac3ede9402bf2b19'
    end
  end
end
