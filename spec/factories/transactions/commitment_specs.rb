# frozen_string_literal: true

FactoryBot.define do
  factory(:commitment_spec, class: 'FactoryBotWrapper') do
    htlcs { Set[] }
    feerate_per_kw { 1000 }
    to_local_msat { 0 }
    to_remote_msat { 0 }
    initialize_with do
      new(Lightning::Transactions::CommitmentSpec[
        htlcs, feerate_per_kw, to_local_msat, to_remote_msat
      ])
    end

    trait(:local) do
      feerate_per_kw { 15000 }
      to_local_msat { 7_000_000_000 }
      to_remote_msat { 3_000_000_000 }
    end

    trait(:remote) do
      feerate_per_kw { 15000 }
      to_local_msat { 3_000_000_000 }
      to_remote_msat { 7_000_000_000 }
    end

    trait(:has_received_htlcs) do
      htlcs do
        htlc = build(:update_add_htlc, id: 0, amount_msat: 20_000_000).get
        Set[build(:directed_htlc, :received, add: htlc).get]
      end
      feerate_per_kw { 15000 }
      to_local_msat { 3_000_000_000 }
      to_remote_msat { 7_000_000_000 }
    end

    trait(:has_offered_htlcs) do
      htlcs do
        htlc = build(:update_add_htlc, id: 0, amount_msat: 20_000_000).get
        Set[build(:directed_htlc, :offered, add: htlc).get]
      end
      feerate_per_kw { 15000 }
      to_local_msat { 3_000_000_000 }
      to_remote_msat { 7_000_000_000 }
    end

    trait(:too_many_htlcs) do
      htlcs do
        set = Set[]
        483.times do |i|
          htlc = build(:update_add_htlc, id: i, amount_msat: 2_000).get
          set << build(:directed_htlc, :received, add: htlc).get
        end
        set
      end
      feerate_per_kw { 15000 }
      to_local_msat { 3_000_000_000 }
      to_remote_msat { 7_000_000_000 }
    end
  end
end
