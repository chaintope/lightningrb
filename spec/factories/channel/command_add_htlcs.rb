# frozen_string_literal: true

FactoryBot.define do
  r = Bitcoin.sha256("\x42" * 32)
  h = Bitcoin.sha256(r)

  factory(:command_add_htlc, class: 'FactoryBotWrapper') do
    amount_msat { 5_000_000 }
    payment_hash { h.bth }
    cltv_expiry { 400 }
    onion { '' }
    upstream_opt { Algebrick::None }
    commit { true }
    initialize_with do
      new(Lightning::Channel::Messages::CommandAddHtlc[
        amount_msat,
        payment_hash,
        cltv_expiry,
        onion,
        upstream_opt,
        commit
      ])
    end

    trait :local do
      upstream_opt { Algebrick::None }
    end

    trait :remote do
      upstream_opt do
        Algebrick::Some[Lightning::Wire::LightningMessages::UpdateMessage][build(:update_add_htlc)]
      end
    end
  end
end
