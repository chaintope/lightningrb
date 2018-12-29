# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::Messages do
  describe 'LocalParam#to_payload/#load' do
    subject { Lightning::Channel::Messages::LocalParam.load(local_param.to_payload) }

    let(:local_param) { build(:local_param).get }

    it { expect(subject[0]).to eq local_param }
  end

  describe 'RemoteParam#to_payload/#load' do
    subject { Lightning::Channel::Messages::RemoteParam.load(remote_param.to_payload) }

    let(:remote_param) { build(:remote_param).get }

    it { expect(subject[0]).to eq remote_param }
  end

  describe 'LocalCommit#to_payload/#load' do
    subject { Lightning::Channel::Messages::LocalCommit.load(local_commit.to_payload) }

    let(:local_commit) { build(:local_commit).get }

    it { expect(subject[0].to_payload.bth).to eq local_commit.to_payload.bth }
  end

  describe 'RemoteCommit#to_payload/#load' do
    subject { Lightning::Channel::Messages::RemoteCommit.load(remote_commit.to_payload) }

    let(:remote_commit) { build(:remote_commit).get }

    it { expect(subject[0].to_payload).to eq remote_commit.to_payload }
  end

  describe 'LocalChanges#to_payload/#load' do
    subject { Lightning::Channel::Messages::LocalChanges.load(local_change.to_payload) }

    let(:local_change) { build(:local_change).get }

    it { expect(subject[0]).to eq local_change }
  end

  describe 'RemoteChanges#to_payload/#load' do
    subject { Lightning::Channel::Messages::RemoteChanges.load(remote_change.to_payload) }

    let(:remote_change) { build(:remote_change).get }

    it { expect(subject[0]).to eq remote_change }
  end

  describe 'WaitingForRevocation#to_payload/#load' do
    subject { Lightning::Channel::Messages::WaitingForRevocation.load(waiting_for_revocation.to_payload) }

    let(:waiting_for_revocation) { build(:waiting_for_revocation).get }

    it { expect(subject[0]).to eq waiting_for_revocation }
  end

  describe 'PublishableTxs#to_payload/load' do
    subject { Lightning::Channel::Messages::PublishableTxs.load(publishable_txs.to_payload) }

    let(:publishable_txs) { build(:publishable_tx).get }

    it { expect(subject[0].to_payload.bth).to eq publishable_txs.to_payload.bth }
  end

  describe 'Commitments#to_poayload/load' do
    subject { Lightning::Channel::Messages::Commitments.load(commitments.to_payload) }

    let(:commitments) { build(:commitment).get }

    it { expect(subject[0].to_payload.bth).to eq commitments.to_payload.bth }
  end
end
