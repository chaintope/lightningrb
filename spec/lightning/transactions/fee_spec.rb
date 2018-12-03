# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Transactions::Fee do
  describe '.commit_tx_fee' do
    # For example, suppose that we have a `feerate_per_kw` of 5000, a `dust_limit_satoshis` of 546 satoshis,
    # and commitment transaction with:
    # * 2 offered HTLCs of 5000000 and 1000000 millisatoshis (5000 and 1000 satoshis)
    # * 2 received HTLCs of 7000000 and 800000 millisatoshis (7000 and 800 satoshis)
    #
    # The HTLC timeout transaction weight is 663, thus fee would be 3315 satoshis.
    # The HTLC success transaction weight is 703, thus fee would be 3515 satoshis
    #
    # The commitment transaction weight would be calculated as follows:
    #
    # * weight starts at 724.
    #
    # * The offered HTLC of 5000 satoshis is above 546 + 3315 and would result in:
    #   * an output of 5000 satoshi in the commitment transaction
    #   * a HTLC timeout transaction of 5000 - 3145 satoshis which spends this output
    #   * weight increases to 896
    #
    # * The offered HTLC of 1000 satoshis is below 546 + 3315, so would be trimmed.
    #
    # * The received HTLC of 7000 satoshis is above 546 + 3590 and would result in:
    #   * an output of 7000 satoshi in the commitment transaction
    #   * a HTLC success transaction of 7000 - 3590 satoshis which spends this output
    #   * weight increases to 1068
    #
    # * The received HTLC of 800 satoshis is below 546 + 3515 so would be trimmed.
    #
    # The base commitment transaction fee would be 5340 satoshi; the actual
    # fee (adding the 1000 and 800 satoshi HTLCs which would have made dust
    # outputs) is 7140 satoshi.  The final fee may even be more if the
    # `to_local` or `to_remote` outputs fall below `dust_limit_satoshis`.
    subject { described_class.commit_tx_fee(546, spec) }

    let(:add1) { build(:update_add_htlc, id: 0, amount_msat: 5_000 * 1_000, cltv_expiry: 552).get }
    let(:add2) { build(:update_add_htlc, id: 0, amount_msat: 1_000 * 1_000, cltv_expiry: 553).get }
    let(:add3) { build(:update_add_htlc, id: 0, amount_msat: 7_000 * 1_000, cltv_expiry: 550).get }
    let(:add4) { build(:update_add_htlc, id: 0, amount_msat: 800 * 1_000, cltv_expiry: 551).get }

    let(:htlc1) { build(:directed_htlc, :offered, add: add1).get }
    let(:htlc2) { build(:directed_htlc, :offered, add: add2).get }
    let(:htlc3) { build(:directed_htlc, :received, add: add3).get }
    let(:htlc4) { build(:directed_htlc, :received, add: add4).get }

    let(:htlcs) { Set[htlc1, htlc2, htlc3, htlc4] }
    let(:spec) { build(:commitment_spec, htlcs: htlcs, feerate_per_kw: 5_000).get }

    it { is_expected.to eq 5340 }
  end
end
