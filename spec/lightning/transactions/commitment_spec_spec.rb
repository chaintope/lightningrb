# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::CommitmentSpec do
  let(:add1) { build(:update_add_htlc, id: 1, amount_msat: 2_000 * 1_000).get }
  let(:add2) { build(:update_add_htlc, id: 2, amount_msat: 1_000 * 1_000).get }
  let(:ful1) { build(:update_fulfill_htlc, id: add1.id).get }
  let(:fail1) { build(:update_fail_htlc, id: add2.id).get }

  describe 'add, fulfill and fail htlcs from the sender side' do
    let(:spec) { build(:commitment_spec, to_local_msat: 5000 * 1000).get }
    let(:htlc1) { build(:directed_htlc, :offered, add: add1).get }
    let(:htlc2) { build(:directed_htlc, :offered, add: add2).get }

    it do
      spec1 = Lightning::Transactions::CommitmentSpec.reduce(spec, [add1], [])
      expect(spec1).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc1], 1000, 3000 * 1000, 0])

      spec2 = Lightning::Transactions::CommitmentSpec.reduce(spec1, [add2], [])
      expect(spec2).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc1, htlc2], 1000, 2000 * 1000, 0])

      spec3 = Lightning::Transactions::CommitmentSpec.reduce(spec2, [], [ful1])
      expect(spec3).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc2], 1000, 2000 * 1000, 2000 * 1000])

      spec4 = Lightning::Transactions::CommitmentSpec.reduce(spec3, [], [fail1])
      expect(spec4).to eq(Lightning::Transactions::CommitmentSpec[Set[], 1000, 3000 * 1000, 2000 * 1000])
    end
  end

  describe 'add, fulfill and fail htlcs from the receiver side' do
    let(:spec) { build(:commitment_spec, to_remote_msat: 5000 * 1000).get }
    let(:htlc1) { build(:directed_htlc, :received, add: add1).get }
    let(:htlc2) { build(:directed_htlc, :received, add: add2).get }

    it do
      spec1 = Lightning::Transactions::CommitmentSpec.reduce(spec, [], [add1])
      expect(spec1).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc1], 1000, 0, 3000 * 1000])

      spec2 = Lightning::Transactions::CommitmentSpec.reduce(spec1, [], [add2])
      expect(spec2).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc1, htlc2], 1000, 0, 2000 * 1000])

      spec3 = Lightning::Transactions::CommitmentSpec.reduce(spec2, [ful1], [])
      expect(spec3).to eq(Lightning::Transactions::CommitmentSpec[Set[htlc2], 1000, 2000 * 1000, 2000 * 1000])

      spec4 = Lightning::Transactions::CommitmentSpec.reduce(spec3, [fail1], [])
      expect(spec4).to eq(Lightning::Transactions::CommitmentSpec[Set[], 1000, 2000 * 1000, 3000 * 1000])
    end
  end

  describe '#to_payload/load' do
    subject { Lightning::Transactions::CommitmentSpec.load(spec.to_payload) }

    let(:spec) { build(:commitment_spec, :has_received_htlcs).get }

    it { expect(subject[0]).to eq spec }
  end
end
