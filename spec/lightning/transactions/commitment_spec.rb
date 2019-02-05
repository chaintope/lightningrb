# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::Commitment do
  let(:spv) { create_test_spv }

  before { spv.stub(:blockchain_info).and_return( 'headers' => 999 ) }

  describe '#obscured_commit_tx_number' do
    # local_payment_basepoint: 034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa
    # remote_payment_basepoint: 032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991
    # obscured commitment transaction number = 0x2bb038521914 ^ 42
    subject do
      described_class.obscured_commit_tx_number(
        commitment_tx_number,
        funder,
        local_payment_base_point,
        remote_payment_base_point
      )
    end

    let(:commitment_tx_number) { 42 }
    let(:funder) { true }
    let(:local_payment_base_point) do
      '034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa'
    end
    let(:remote_payment_base_point) do
      '032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991'
    end

    it { is_expected.to eq 0x2bb038521914 ^ 42 }
  end

  describe '#encode_tx_number' do
    subject { described_class.encode_tx_number(commitment_tx_number) }

    let(:commitment_tx_number) { 0x11F71FB268D }

    it { expect(subject[0]).to eq 0x80011F71 }
    it { expect(subject[1]).to eq 0x20FB268D }
  end

  describe '#decode_tx_number' do
    subject { described_class.decode_tx_number(sequence, lock_time) }

    let(:sequence) { 0x80011F71 }
    let(:lock_time) { 0x20FB268D }

    it { expect(subject).to eq 0x11F71FB268D }
  end

  describe '.send_add' do
    subject(:result) { Lightning::Transactions::Commitment.send_add(commitments, cmd, origin, spv) }

    let(:cmd) { build(:command_add_htlc, cltv_expiry: cltv_expiry, amount_msat: amount_msat).get }
    let(:origin) { '' }
    let(:spec) { build(:commitment_spec, :remote).get }
    let(:remote_commit) { build(:remote_commit, spec: spec).get }
    let(:local_next_htlc_id) { 0 }
    let(:commitments) do
      build(:commitment,
            remote_commit: remote_commit,
            local_next_htlc_id: local_next_htlc_id).get
    end
    let(:amount_msat) { 5_000_000 }
    let(:cltv_expiry) { 499_999_999 }
    let(:max_accepted_htlcs) { 483 }

    # [BOLT-2](02-peer-protocol.md#requirements-9)
    describe 'A sending node:' do
      xdescribe '' do
        it 'MUST NOT offer amount_msat it cannot pay for in the remote commitment transaction at ' \
          'the current feerate_per_kw while maintaining its channel reserve.' do
          pending("Not implement #{__LINE__}")
        end
      end

      describe 'MUST offer amount_msat greater than 0.' do
        let(:amount_msat) { 0 }

        it { is_expected.to be_kind_of Lightning::Exceptions::HtlcValueTooSmall }
      end

      describe 'MUST NOT offer amount_msat below the receiving node\'s htlc_minimum_msat' do
        let(:amount_msat) { 4_999_999 }

        it { is_expected.to be_kind_of Lightning::Exceptions::HtlcValueTooSmall }
      end

      describe 'MUST set cltv_expiry less than 500000000.' do
        let(:cltv_expiry) { 500_000_000 }

        it { is_expected.to be_kind_of Lightning::Exceptions::ExpiryTooLarge }
      end

      context 'for channels with chain_hash identifying the Bitcoin blockchain:' do
        let(:amount_msat) { 0x00000000FFFFFFFF + 1 }

        it 'MUST set the four most significant bytes of amount_msat to 0.' do
          is_expected.to be_kind_of Lightning::Exceptions::HtlcValueTooLarge
        end
      end

      context 'if result would be offering more than the remote\'s max_accepted_htlcs HTLCs,' \
        ' in the remote commitment transaction:' do
        let(:commitments) do
          build(:commitment,
                remote_commit: remote_commit,
                local_next_htlc_id: local_next_htlc_id,
                remote_next_commit_info: '').get
        end
        let(:spec) { build(:commitment_spec, :too_many_htlcs).get }

        it 'MUST NOT add an HTLC.' do
          is_expected.to be_kind_of Lightning::Exceptions::TooManyAcceptedHtlcs
        end
      end

      context 'if the sum of total offered HTLCs would exceed the remote\'s ' \
        'max_htlc_value_in_flight_msat:' do
        let(:amount_msat) { 100_000_001 }

        it 'MUST NOT add an HTLC.' do
          is_expected.to be_kind_of Lightning::Exceptions::HtlcValueTooHighInFlight
        end
      end

      context 'for the first HTLC it offers:' do
        it 'MUST set id to 0.' do
          expect(subject[1].id).to eq 0
        end
      end

      describe 'MUST increase the value of id by 1 for each successive offer.' do
        let(:local_next_htlc_id) { 10 }

        it { expect(subject[0][:local_next_htlc_id]).to eq 11 }
      end
    end
  end

  describe '.receive_add' do
    subject(:result) { Lightning::Transactions::Commitment.receive_add(commitments, add, spv) }

    let(:spec) { build(:commitment_spec, :local).get }
    let(:local_commit) { build(:local_commit, spec: spec).get }
    let(:local_param) do
      build(
        :local_param,
        max_accepted_htlcs: max_accepted_htlcs
      ).get
    end
    let(:commitments) do
      build(:commitment, local_param: local_param, local_commit: local_commit).get
    end
    let(:amount_msat) { 5_000_000 }
    let(:cltv_expiry) { 499_999_999 }
    let(:max_accepted_htlcs) { 483 }
    let(:add) do
      build(
        :update_add_htlc,
        id: 2,
        amount_msat: amount_msat,
        cltv_expiry: cltv_expiry
      )
    end

    # [BOLT-2](02-peer-protocol.md#requirements-9)
    describe 'A receiving node:' do
      context 'receiving an amount_msat equal to 0, OR less than its own htlc_minimum_msat:' do
        let(:amount_msat) { 4_999_999 }

        it 'SHOULD fail the channel (HtlcValueTooSmall)' do
          expect { subject }.to raise_error Lightning::Exceptions::HtlcValueTooSmall
        end
      end

      context 'if a sending node adds more than its max_accepted_htlcs HTLCs' \
        ' to its local commitment transaction:' do
        let(:spec) { build(:commitment_spec, :too_many_htlcs).get }

        it 'SHOULD fail the channel (TooManyAcceptedHtlcs)' do
          expect { subject }.to raise_error Lightning::Exceptions::TooManyAcceptedHtlcs
        end
      end

      context 'OR adds more than its max_htlc_value_in_flight_msat worth of offered HTLCs' \
        ' to its local commitment transaction:' do
        let(:amount_msat) { 100_000_001 }

        it 'SHOULD fail the channel (HtlcValueTooHighInFlight)' do
          expect { subject }.to raise_error Lightning::Exceptions::HtlcValueTooHighInFlight
        end
      end

      context 'if sending node sets cltv_expiry to greater or equal to 500000000:' do
        let(:cltv_expiry) { 500_000_000 }

        it 'SHOULD fail the channel (ExpiryTooLarge)' do
          expect { subject }.to raise_error Lightning::Exceptions::ExpiryTooLarge
        end
      end

      context 'for channels with chain_hash identifying the Bitcoin blockchain, if the four most' \
        ' significant bytes of amount_msat are not 0:' do
        let(:amount_msat) { 0x00000000FFFFFFFF + 1 }

        it 'SHOULD fail the channel (HtlcValueTooLarge)' do
          expect { subject }.to raise_error Lightning::Exceptions::HtlcValueTooLarge
        end
      end

      it 'MUST allow multiple HTLCs with the same payment_hash.' do
        subject
        expect { subject }.not_to raise_error
      end

      xcontext 'if the sender did not previously acknowledge the commitment of that HTLC:' do
        it 'MUST ignore a repeated id value after a reconnection.' do
        end
      end

      xcontext 'if other id violations occur:' do
        it 'MAY fail the channel.' do
        end
      end
    end
  end

  describe '.receive_fulfill' do
    subject { Lightning::Transactions::Commitment.receive_fulfill(commitment, fulfill) }

    let(:fulfill) { build(:update_fulfill_htlc) }
    let(:commitment) do
      build(:commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs, remote_next_commit_info: '').get
    end

    describe 'A receiving node:' do
      context 'if the `id` does not correspond to an HTLC in its current commitment transaction:' do
        let(:fulfill) { build(:update_fulfill_htlc, id: 999) }

        it 'MUST fail the channel.' do
          expect { subject }.to raise_error(Lightning::Exceptions::UnknownHtlcId)
        end
      end

      context 'if the payment_preimage value in update_fulfill_htlc doesn\'t SHA256 hash to the corresponding HTLC payment_hash:' do
        let(:fulfill) { build(:update_fulfill_htlc, payment_preimage: Bitcoin.sha256("\x00" * 32)) }

        it 'MUST fail the channel' do
          expect { subject }.to raise_error(Lightning::Exceptions::InvalidHtlcPreimage)
        end
      end

      context 'otherwise' do
        it { expect { subject }.not_to raise_error }
      end
    end
  end

  describe '.receive_fail' do
    subject(:result) { Lightning::Transactions::Commitment.receive_fail(commitment, fail) }

    let(:fail) { build(:update_fail_htlc) }
    let(:commitment) { build(:commitment, :funder).get }

    describe 'A receiving node:' do
      context 'if the `id` does not correspond to an HTLC in its current commitment transaction:' do
        it 'MUST fail the channel.' do
          expect { subject }.to raise_error(Lightning::Exceptions::UnknownHtlcId)
        end
      end

      context 'otherwise' do
        let(:commitment) { build(:commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs).get }

        it { expect { subject }.not_to raise_error }
      end
    end
  end

  describe '.receive_fail_malformed' do
    subject { Lightning::Transactions::Commitment.receive_fail_malformed(commitment, fail_malformed) }

    let(:fail_malformed) { build(:update_fail_malformed_htlc) }
    let(:commitment) { build(:commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs).get }

    describe 'A receiving node:' do
      context 'if the `id` does not correspond to an HTLC in its current commitment transaction:' do
        let(:fail_malformed) { build(:update_fail_malformed_htlc, id: 999) }

        it 'MUST fail the channel.' do
          expect { subject }.to raise_error(Lightning::Exceptions::UnknownHtlcId)
        end
      end

      context 'if the BADONION bit in failure_code is not set for update_fail_malformed_htlc:' do
        let(:fail_malformed) do
          build(
            :update_fail_malformed_htlc,
            failure_code: Lightning::Onion::FailureMessages::TYPES[:permanent_channel_failure]
          )
        end

        it 'MUST fail the channel.' do
          expect { subject }.to raise_error(Lightning::Exceptions::InvalidFailureCode)
        end
      end

      xcontext 'if the sha256_of_onion in update_fail_malformed_htlc doesn\'t match the onion it sent: ' do
        it 'MAY retry or choose an alternate error response.' do
        end
      end

      context 'otherwise' do
        it { expect { subject }.not_to raise_error }
      end
    end
  end

  describe '.send_commit' do
    subject { Lightning::Transactions::Commitment.send_commit(commitment) }

    describe 'A sending node:' do
      let(:update) { build(:update_add_htlc) }
      let(:local_change) { build(:local_change, proposed: [update]).get }
      let(:remote_next_commit_info) { '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486' }
      let(:commitment) do
        build(
          :commitment,
          :funder,
          local_change: local_change,
          remote_next_commit_info: remote_next_commit_info
        ).get
      end

      describe 'MUST NOT send a commitment_signed message that does not include any updates.' do
        let(:local_change) { build(:local_change, acked: []).get }

        it { expect { subject }.to raise_error(Lightning::Exceptions::CannotSignWithoutChanges) }
      end

      describe do
        xit 'MAY send a commitment_signed message that only alters the fee.' do
        end
      end

      describe do
        xit 'MAY send a commitment_signed message that doesn\'t change the commitment transaction aside from the new revocation hash.' do
          # (due to dust, identical HTLC replacement, or insignificant or multiple fee changes)
        end
      end

      describe 'for every HTLC transaction corresponding to BIP69 lexicographic ordering of the commitment transaction' do
        xit 'MUST include one htlc_signature.' do
        end
      end

      context 'otherwise' do
        it { expect { subject }.not_to raise_error }
      end
    end
  end

  describe '.receive_commit' do
    subject(:result) { Lightning::Transactions::Commitment.receive_commit(commitment, commitment_signed) }

    let(:commitment_signed) { build(:commitment_signed, htlc_signature: htlc_signature) }
    let(:htlc_signature) { [] }
    let(:update) { build(:update_add_htlc) }
    let(:local_change) { build(:local_change, acked: [update]).get }
    let(:commitment) do
      build(:commitment, :funder, local_change: local_change).get
    end

    before { allow(Lightning::Transactions).to receive(:add_sigs).and_return(Bitcoin::Tx.new) }

    describe 'A receiving node:' do
      context 'once all pending updates are applied:' do
        context 'if signature is not valid for its local commitment transaction:' do

          before { allow(Lightning::Transactions).to receive(:add_sigs).and_raise('invalid sig') }

          it 'MUST fail the channel.' do
            expect { subject }.to raise_error(Lightning::Exceptions::InvalidCommitmentSignature)
          end
        end

        context 'if num_htlcs is not equal to the number of HTLC outputs in the local commitment transaction:' do
          let(:htlc_signature) do
            [
              Lightning::Wire::Signature.new(value: '77' * 32),
              Lightning::Wire::Signature.new(value: '88' * 32),
            ]
          end

          it 'MUST fail the channel.' do
            expect { subject }.to raise_error(Lightning::Exceptions::HtlcSigCountMismatch)
          end
        end
      end

      context 'if any htlc_signature is not valid for the corresponding HTLC transaction:' do
        let(:commitment_signed) do
          build(
            :commitment_signed,
            htlc_signature: htlc_signature
          )
        end
        let(:commitment) do
          build(
            :commitment,
            :funder,
            :has_remote_received_htlcs,
            :has_local_offered_htlcs,
            local_change: local_change
          ).get
        end
        let(:htlc_signature) do
          [
            Lightning::Wire::Signature.new(value:
              '304402202e807ac73c2726a92b5f36df8987025039968bee8a985ae1d699014c' \
              '3d8be45f02201c545477a57a547fe99b2e3e8326f7f399283448aedf03d20505' \
              '9782bd181b3c'
            ),
          ]
        end

        it 'MUST fail the channel.' do
          expect { subject }.to raise_error(Lightning::Exceptions::InvalidHtlcSignature)
        end
      end

      it 'MUST respond with a revoke_and_ack message' do
        expect(result[1]).to be_a Lightning::Wire::LightningMessages::RevokeAndAck
      end
    end
  end
end
