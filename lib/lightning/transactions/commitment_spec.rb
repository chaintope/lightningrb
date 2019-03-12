# frozen_string_literal: true

module Lightning
  module Transactions
    CommitmentSpec = Algebrick.type do
      fields! htlcs: Set,
              feerate_per_kw: Numeric,
              to_local_msat: Numeric,
              to_remote_msat: Numeric
    end

    module CommitmentSpec
      OFFER = 0
      RECEIVE = 1

      def offered
        htlcs.select { |v| v[:direction] == OFFER }
      end

      def received
        htlcs.select { |v| v[:direction] == RECEIVE }
      end

      def to_payload
        payload = StringIO.new
        payload << [self[:htlcs].length].pack('n')
        self[:htlcs].each do |htlc|
          payload << htlc.to_payload
        end
        payload << [self[:feerate_per_kw], self[:to_local_msat], self[:to_remote_msat]].pack('q>3')
        payload.string
      end

      def self.load(payload)
        len, rest = payload.unpack('na*')
        htlcs = Set.new
        len.times do |i|
          htlc, rest = DirectedHtlc.load(rest)
          htlcs << htlc
        end
        feerate_per_kw, to_local_msat, to_remote_msat, rest = rest.unpack('q>3a*')
        [new(htlcs, feerate_per_kw, to_local_msat, to_remote_msat), rest]
      end

      def self.reduce(local_commit_spec, local_changes, remote_changes)
        spec1 = local_changes.inject(local_commit_spec) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateAddHtlc
            add_htlc(spec, OFFER, change)
          else spec
          end
        end
        spec2 = remote_changes.inject(spec1) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateAddHtlc
            add_htlc(spec, RECEIVE, change)
          else spec
          end
        end
        spec3 = local_changes.inject(spec2) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateFulfillHtlc
            fulfill_htlc(spec, OFFER, change.id)
          when Lightning::Wire::LightningMessages::UpdateFailHtlc
            fail_htlc(spec, OFFER, change.id)
          when Lightning::Wire::LightningMessages::UpdateFailMalformedHtlc
            fail_htlc(spec, OFFER, change.id)
          else spec
          end
        end
        spec4 = remote_changes.inject(spec3) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateFulfillHtlc
            fulfill_htlc(spec, RECEIVE, change.id)
          when Lightning::Wire::LightningMessages::UpdateFailHtlc
            fail_htlc(spec, RECEIVE, change.id)
          when Lightning::Wire::LightningMessages::UpdateFailMalformedHtlc
            fail_htlc(spec, RECEIVE, change.id)
          else spec
          end
        end
        spec5 = local_changes.inject(spec4) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateFee
            fee_htlc(spec, change.feerate_per_kw)
          else spec
          end
        end
        _ = remote_changes.inject(spec5) do |spec, change|
          case change
          when Lightning::Wire::LightningMessages::UpdateFee
            fee_htlc(spec, change.feerate_per_kw)
          else spec
          end
        end
      end

      def self.add_htlc(spec, direction, change)
        htlc = DirectedHtlc[direction, change]
        htlcs = spec.htlcs.dup
        htlcs << htlc
        to_local_msat, to_remote_msat =
          case direction
          when OFFER
            [spec.to_local_msat - htlc.add.amount_msat, spec.to_remote_msat]
          when RECEIVE
            [spec.to_local_msat, spec.to_remote_msat - htlc.add.amount_msat]
          end
        CommitmentSpec[htlcs, spec.feerate_per_kw, to_local_msat, to_remote_msat]
      end

      def self.fulfill_htlc(spec, direction, htlc_id)
        htlc = spec.htlcs.find { |h| h.direction != direction && h.add.id == htlc_id }
        raise "cannot find htlc id=#{htlc_id}" unless htlc
        htlcs = spec.htlcs.dup
        htlcs.delete(htlc)
        to_local_msat, to_remote_msat =
          case direction
          when OFFER
            [spec.to_local_msat + htlc.add.amount_msat, spec.to_remote_msat]
          when RECEIVE
            [spec.to_local_msat, spec.to_remote_msat + htlc.add.amount_msat]
          end
        CommitmentSpec[htlcs, spec.feerate_per_kw, to_local_msat, to_remote_msat]
      end

      def self.fail_htlc(spec, direction, htlc_id)
        htlc = spec.htlcs.find { |h| h.direction != direction && h.add.id == htlc_id }
        raise "cannot find htlc id=#{htlc_id}" unless htlc
        htlcs = spec.htlcs.dup
        htlcs.delete(htlc)
        to_local_msat, to_remote_msat =
          case direction
          when OFFER
            [spec.to_local_msat, spec.to_remote_msat + htlc.add.amount_msat]
          when RECEIVE
            [spec.to_local_msat + htlc.add.amount_msat, spec.to_remote_msat]
          end
        CommitmentSpec[htlcs, spec.feerate_per_kw, to_local_msat, to_remote_msat]
      end

      def self.fee_htlc(spec, new_fee)
        CommitmentSpec[spec.htlcs, new_fee, spec.to_local_msat, spec.to_remote_msat]
      end
    end
  end
end
