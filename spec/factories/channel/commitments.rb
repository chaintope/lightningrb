# frozen_string_literal: true

FactoryBot.define do
  factory(:commitment, class: 'FactoryBotWrapper') do
    local_param { build(:local_param).get }
    remote_param { build(:remote_param).get }
    channel_flags { 0 }
    local_commit { build(:local_commit).get }
    remote_commit { build(:remote_commit).get }
    local_change { build(:local_change).get }
    remote_change { build(:remote_change).get }
    local_next_htlc_id { 0 }
    remote_next_htlc_id { 0 }
    origin_channels { {} }
    remote_next_commit_info { build(:waiting_for_revocation).get }
    commit_input { build(:utxo, :multisig) }
    remote_per_commitment_secrets { ["\x00" * 32] }
    channel_id { '8984484a580b825b9972d7adb15050b3ab624ccd731946b3eeddb92f4e7ef6ff' }
    initialize_with do
      new(Lightning::Channel::Messages::Commitments[
        local_param: local_param,
        remote_param: remote_param,
        channel_flags: channel_flags,
        local_commit: local_commit,
        remote_commit: remote_commit,
        local_changes: local_change,
        remote_changes: remote_change,
        local_next_htlc_id: local_next_htlc_id,
        remote_next_htlc_id: remote_next_htlc_id,
        origin_channels: origin_channels,
        remote_next_commit_info: remote_next_commit_info,
        commit_input: commit_input,
        remote_per_commitment_secrets: remote_per_commitment_secrets,
        channel_id: channel_id
      ])
    end

    trait :funder do
      local_param { build(:local_param, :funder).get }
    end

    trait :fundee do
      local_param { build(:local_param, :fundee).get }
    end

    trait :has_local_received_htlcs do
      local_commit { build(:local_commit, :has_received_htlcs).get }
    end

    trait :has_remote_received_htlcs do
      remote_commit { build(:remote_commit, :has_received_htlcs).get }
    end

    trait :has_local_offered_htlcs do
      local_commit { build(:local_commit, :has_offered_htlcs).get }
    end

    trait :has_remote_offered_htlcs do
      remote_commit { build(:remote_commit, :has_offered_htlcs).get }
    end
  end
end
