# frozen_string_literal: true

module Lightning
  module Channel
    module Messages
      include Lightning::Wire::LightningMessages

      ## Command
      CommandAddHtlc = Algebrick.type do
        fields! amount_msat: Numeric,
                payment_hash: String,
                cltv_expiry: Numeric,
                onion: String,
                upstream_opt: Algebrick::Maybe[UpdateAddHtlc],
                commit: Algebrick::Boolean
      end

      CommandFulfillHtlc = Algebrick.type do
        fields! id: Numeric,
                r: String,
                commit: Algebrick::Boolean
      end

      CommandFailHtlc = Algebrick.type do
        fields! id: Numeric,
                reason: Object,
                commit: Algebrick::Boolean
      end

      CommandFailMalformedHtlc = Algebrick.type do
        fields! id: Numeric,
                onion_hash: String,
                failure_code: Numeric,
                commit: Algebrick::Boolean
      end

      CommandUpdateFee = Algebrick.type do
        fields! feerate_per_kw: Numeric,
                commit: Algebrick::Boolean
      end

      CommandClose = Algebrick.type do
        fields! script_pubkey: Algebrick::Maybe[String]
      end

      CommandSignature = Algebrick.atom

      CommandAck = Algebrick.type do
        fields! channel_id: String,
                id: Numeric
      end

      Command = Algebrick.type do
        variants  CommandAddHtlc,
                  CommandFulfillHtlc,
                  CommandFailHtlc,
                  CommandFailMalformedHtlc,
                  CommandUpdateFee,
                  CommandClose,
                  CommandSignature,
                  CommandAck
      end

      ## Data
      LocalParam = Algebrick.type do
        fields! node_id: String,
                dust_limit_satoshis: Numeric,
                max_htlc_value_in_flight_msat: Numeric,
                channel_reserve_satoshis: Numeric,
                htlc_minimum_msat: Numeric,
                to_self_delay: Numeric,
                max_accepted_htlcs: Numeric,
                funding_priv_key: Bitcoin::Key,
                revocation_secret: Numeric,
                payment_key: Numeric,
                delayed_payment_key: Numeric,
                htlc_key: Numeric,
                default_final_script_pubkey: String,
                sha_seed: String,
                funder: Numeric,
                globalfeatures: String,
                localfeatures: String
      end
      module LocalParam
        def payment_basepoint
          Bitcoin::Key.new(priv_key: payment_key.to_s(16).rjust(64, '0')).pubkey
        end

        def delayed_payment_basepoint
          Bitcoin::Key.new(priv_key: delayed_payment_key.to_s(16).rjust(64, '0')).pubkey
        end

        def revocation_basepoint
          Bitcoin::Key.new(priv_key: revocation_secret.to_s(16).rjust(64, '0')).pubkey
        end

        def htlc_basepoint
          Bitcoin::Key.new(priv_key: htlc_key.to_s(16).rjust(64, '0')).pubkey
        end

        def funder?
          funder == 1
        end

        def self.builder
          @builder ||= Lightning::Utils::Serializer.new.
            public_key.uint64.x(4).uint16.x(2).bitcoin_key.uint64.x(4).pascal_string.binary(32).char.pascal_string.x(2)
        end

        def self.unpack(payload)
          args = builder.to_a(payload)
          [new(*(args[0])), args[1]]
        end

        def pack
          LocalParam.builder.to_binary(*to_a)
        end

        def to_payload
          pack
        end

        def self.load(payload)
          unpack(payload)
        end

        def ==(other)
          return false unless other.is_a? Lightning::Channel::Messages::LocalParam
          to_payload.eql?(other.to_payload)
        end
      end

      RemoteParam = Algebrick.type do
        fields! node_id: String,
                dust_limit_satoshis: Numeric,
                max_htlc_value_in_flight_msat: Numeric,
                channel_reserve_satoshis: Numeric,
                htlc_minimum_msat: Numeric,
                to_self_delay: Numeric,
                max_accepted_htlcs: Numeric,
                funding_pubkey: String,
                revocation_basepoint: String,
                payment_basepoint: String,
                delayed_payment_basepoint: String,
                htlc_basepoint: String,
                globalfeatures: String,
                localfeatures: String
      end

      module RemoteParam
        def to_payload
          payload = +''
          payload << self[:node_id].htb
          payload << [self[:dust_limit_satoshis]].pack('q>')
          payload << [self[:max_htlc_value_in_flight_msat]].pack('q>')
          payload << [self[:channel_reserve_satoshis]].pack('q>')
          payload << [self[:htlc_minimum_msat]].pack('q>')
          payload << [self[:to_self_delay]].pack('n')
          payload << [self[:max_accepted_htlcs]].pack('n')
          payload << self[:funding_pubkey].htb
          payload << self[:revocation_basepoint].htb
          payload << self[:payment_basepoint].htb
          payload << self[:delayed_payment_basepoint].htb
          payload << self[:htlc_basepoint].htb
          payload << [self[:globalfeatures].htb.bytesize].pack('n')
          payload << self[:globalfeatures].htb
          payload << [self[:localfeatures].htb.bytesize].pack('n')
          payload << self[:localfeatures].htb
          payload
        end

        def self.load(payload)
          node_id, rest = payload.unpack('H66a*')
          dust_limit_satoshis, rest = rest.unpack('q>a*')
          max_htlc_value_in_flight_msat, rest = rest.unpack('q>a*')
          channel_reserve_satoshis, rest = rest.unpack('q>a*')
          htlc_minimum_msat, rest = rest.unpack('q>a*')
          to_self_delay, rest = rest.unpack('na*')
          max_accepted_htlcs, rest = rest.unpack('na*')
          funding_pubkey, rest = rest.unpack('H66a*')
          revocation_basepoint, rest = rest.unpack('H66a*')
          payment_basepoint, rest = rest.unpack('H66a*')
          delayed_payment_basepoint, rest = rest.unpack('H66a*')
          htlc_basepoint, rest = rest.unpack('H66a*')
          len, rest = rest.unpack('na*')
          globalfeatures, rest = rest.unpack("H#{2 * len}a*")
          len, rest = rest.unpack('na*')
          localfeatures, rest = rest.unpack("H#{2 * len}a*")
          param = new(
            node_id,
            dust_limit_satoshis,
            max_htlc_value_in_flight_msat,
            channel_reserve_satoshis,
            htlc_minimum_msat,
            to_self_delay,
            max_accepted_htlcs,
            funding_pubkey,
            revocation_basepoint,
            payment_basepoint,
            delayed_payment_basepoint,
            htlc_basepoint,
            globalfeatures,
            localfeatures
          )
          [param, rest]
        end
      end

      LocalChanges = Algebrick.type do
        fields! proposed: Array,
                signed: Array,
                acked: Array
      end

      module LocalChanges
        def all
          proposed + signed + acked
        end

        def copy(proposed: self[:proposed], signed: self[:signed], acked: self[:acked])
          LocalChanges[proposed, signed, acked]
        end

        def to_payload
          payload = +''
          len = self[:proposed].length
          payload << [len].pack('n')
          self[:proposed].map do |c|
            payload << c.to_payload
          end

          len = self[:signed].length
          payload << [len].pack('n')
          self[:signed].map do |c|
            payload << c.to_payload
          end

          len = self[:acked].length
          payload << [len].pack('n')
          self[:acked].map do |c|
            payload << c.to_payload
          end
          payload
        end

        def self.load(payload)
          len, rest = payload.unpack('na*')
          proposed = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            proposed << update
          end

          len, rest = rest.unpack('na*')
          signed = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            signed << update
          end

          len, rest = rest.unpack('na*')
          acked = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            acked << update
          end

          [new(proposed, signed, acked), rest]
        end
      end

      RemoteChanges = Algebrick.type do
        fields! proposed: Array,
                acked: Array,
                signed: Array
      end

      module RemoteChanges
        def copy(proposed: self[:proposed], acked: self[:acked], signed: self[:signed])
          RemoteChanges[proposed, acked, signed]
        end

        def to_payload
          payload = +''
          len = self[:proposed].length
          payload << [len].pack('n')
          self[:proposed].map do |c|
            payload << c.to_payload
          end

          len = self[:acked].length
          payload << [len].pack('n')
          self[:acked].map do |c|
            payload << c.to_payload
          end

          len = self[:signed].length
          payload << [len].pack('n')
          self[:signed].map do |c|
            payload << c.to_payload
          end

          payload
        end

        def self.load(payload)
          len, rest = payload.unpack('na*')
          proposed = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            proposed << update
          end

          len, rest = rest.unpack('na*')
          acked = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            acked << update
          end

          len, rest = rest.unpack('na*')
          signed = []
          len.times do
            update, rest = Lightning::Wire::LightningMessages::UpdateAddHtlc.load(rest)
            signed << update
          end

          [new(proposed, acked, signed), rest]
        end
      end

      Changes = Algebrick.type do
        fields! our_changes: LocalChanges,
                their_changes: RemoteChanges
      end

      TransactionWithUtxo = Algebrick.type do
        fields! tx: Bitcoin::Tx,
                utxo: Lightning::Transactions::Utxo
      end

      module TransactionWithUtxo
        def to_payload
          payload = +''
          payload << [self[:tx].to_payload.bytesize].pack('n')
          payload << self[:tx].to_payload
          payload << self[:utxo].to_payload
          payload
        end

        def self.load(payload)
          len, rest = payload.unpack('na*')
          tx_payload, rest = rest.unpack("a#{len}a*")
          tx = Bitcoin::Tx.parse_from_payload(tx_payload)
          utxo, rest = Lightning::Transactions::Utxo.load(rest)
          [new(tx, utxo), rest]
        end
      end

      HtlcTxAndSigs = Algebrick.type do
        fields! tx: TransactionWithUtxo,
                local_sig: String,
                remote_sig: String
      end

      module HtlcTxAndSigs
        def to_payload
          payload = +''
          payload << [self[:tx].to_payload.bytesize].pack('n')
          payload << self[:tx].to_payload
          payload << [self[:local_sig].htb.bytesize].pack('n')
          payload << self[:local_sig].htb
          payload << [self[:remote_sig].htb.bytesize].pack('n')
          payload << self[:remote_sig].htb
          payload
        end

        def self.load(payload)
          len, rest = payload.unpack('na*')
          tx_payload, rest = rest.unpack("a#{len}a*")
          tx = Bitcoin::Tx.parse_from_payload(tx_payload)
          len, rest = rest.unpack('na*')
          local_sig, rest = rest.unpack("H#{2 * len}a*")
          len, rest = rest.unpack('na*')
          remote_sig, rest = rest.unpack("H#{2 * len}a*")
          [new(tx, local_sig, remote_sig), rest]
        end
      end

      PublishableTxs = Algebrick.type do
        fields! commit_tx: TransactionWithUtxo,
                htlc_txs_and_sigs: Array
      end

      module PublishableTxs
        def to_payload
          payload = +''
          payload << self[:commit_tx].to_payload
          payload << [self[:htlc_txs_and_sigs].length].pack('n')
          self[:htlc_txs_and_sigs].each do |htlc_txs_and_sig|
            payload << htlc_txs_and_sig.to_payload
          end
          payload
        end

        def self.load(payload)
          commit_tx, rest = TransactionWithUtxo.load(payload)
          htlc_txs_and_sigs = []
          len, rest = rest.unpack('na*')
          len.times do
            htlc_txs_and_sig, rest = HtlcTxAndSigs.load(rest)
            htlc_txs_and_sigs << htlc_txs_and_sig
          end
          [new(commit_tx, htlc_txs_and_sigs), rest]
        end
      end

      LocalCommit = Algebrick.type do
        fields! index: Numeric,
                spec: Lightning::Transactions::CommitmentSpec,
                publishable_txs: PublishableTxs
      end

      module LocalCommit
        def to_payload
          payload = +''
          payload << [self[:index]].pack('n')
          payload << self[:spec].to_payload
          payload << self[:publishable_txs].to_payload
          payload
        end

        def self.load(payload)
          index, rest = payload.unpack('na*')
          spec, rest = Lightning::Transactions::CommitmentSpec.load(rest)
          publishable_txs, rest = PublishableTxs.load(rest)
          [new(index, spec, publishable_txs), rest]
        end
      end

      RemoteCommit = Algebrick.type do
        fields! index: Numeric,
                spec: Lightning::Transactions::CommitmentSpec,
                txid: String,
                remote_per_commitment_point: String
      end

      module RemoteCommit
        def to_payload
          payload = +''
          payload << [self[:index]].pack('n')
          payload << self[:spec].to_payload
          payload << self[:txid].htb
          payload << self[:remote_per_commitment_point].htb
          payload
        end

        def self.load(payload)
          index, rest = payload.unpack('na*')
          spec, rest = Lightning::Transactions::CommitmentSpec.load(rest)
          txid, rest = rest.unpack('H64a*')
          remote_per_commitment_point, rest = rest.unpack('H66a*')
          [new(index, spec, txid, remote_per_commitment_point), rest]
        end
      end

      WaitingForRevocation = Algebrick.type do
        fields! next_remote_commit: RemoteCommit,
                sent: CommitmentSigned,
                sent_after_local_commit_index: Numeric,
                re_sign_asap: Algebrick::Boolean
      end

      module WaitingForRevocation
        def to_payload
          payload = +''
          payload << self[:next_remote_commit].to_payload
          sent = self[:sent].to_payload
          payload << [sent.bytesize].pack('n')
          payload << sent
          payload << [self[:sent_after_local_commit_index]].pack('N')
          payload << [self[:re_sign_asap] ? 1 : 0].pack('C')
          payload
        end

        def self.load(payload)
          next_remote_commit, rest = RemoteCommit.load(payload)
          len, rest = rest.unpack('na*')
          sent = Lightning::Wire::LightningMessages::CommitmentSigned.load(rest[0...len])
          sent_after_local_commit_index, rest = rest[len..-1].unpack('Na*')
          re_sign_asap, rest = rest.unpack('Ca*')
          [new(next_remote_commit, sent, sent_after_local_commit_index, re_sign_asap == 1), rest]
        end
      end

      ## Message
      ClosingTxProposed = Algebrick.type do
        fields! unsigned_tx: Bitcoin::Tx,
                local_closing_signed: ClosingSigned
      end
      LocalCommitPublished = Algebrick.type do
        fields! commit_tx: Bitcoin::Tx,
                claim_main_delayed_output_tx: Algebrick::Maybe[Bitcoin::Tx],
                htlc_success_txs: Array,
                htlc_timeout_txs: Array,
                claim_htlc_delayed_tx: Array,
                irrevocably_spent: Hash
      end
      RemoteCommitPublished = Algebrick.type do
        fields! commit_tx: Bitcoin::Tx,
                claim_main_output_tx: Algebrick::Maybe[Bitcoin::Tx],
                claim_htlc_success_txs: Array,
                claim_htlc_timeout_txs: Array,
                irrevocably_spent: Hash
      end
      RevokedCommitPublished = Algebrick.type do
        fields! commit_tx: Bitcoin::Tx,
                claim_main_output_tx: Algebrick::Maybe[Bitcoin::Tx],
                main_penalty_tx: Algebrick::Maybe[Bitcoin::Tx],
                claim_htlc_timeout_txs: Array,
                htlc_timeout_txs: Array,
                htlc_penalty_txs: Array,
                irrevocably_spent: Hash
      end

      Commitments = Algebrick.type do
        fields  local_param: LocalParam,
                remote_param: RemoteParam,
                channel_flags: Numeric,
                local_commit: LocalCommit,
                remote_commit: RemoteCommit,
                local_changes: LocalChanges,
                remote_changes: RemoteChanges,
                local_next_htlc_id: Numeric,
                remote_next_htlc_id: Numeric,
                origin_channels: Hash,
                remote_next_commit_info: type { variants WaitingForRevocation, String },
                commit_input: Lightning::Transactions::Utxo,
                remote_per_commitment_secrets: Array,
                channel_id: String
      end

      module HasCommitments
        def channel_id
          self[:commitments][:channel_id]
        end

        def self.load(payload)
          type, rest = payload.unpack('Ca*')
          case type
          when 1
            DataWaitForFundingConfirmed.load(payload)
          when 2
            DataWaitForFundingLocked.load(payload)
          when 3
            DataNormal.load(payload)
          end
        end
      end

      InputInitFunder = Algebrick.type do
        fields! temporary_channel_id: String,
                funding_satoshis: Numeric,
                push_msat: Numeric,
                initial_feerate_per_kw: Numeric,
                local_param: LocalParam,
                remote: Concurrent::Actor::Reference,
                remote_init: Init,
                channel_flags: Numeric
      end
      InputInitFundee = Algebrick.type do
        fields! temporary_channel_id: String,
                local_param: LocalParam,
                remote: Concurrent::Actor::Reference,
                remote_init: Init
      end
      InputCloseCompleteTimeout = Algebrick.atom
      InputPublishLocalcommit = Algebrick.atom
      InputDisconnected = Algebrick.atom
      InputReconnected = Algebrick.type do
        fields! remote: Concurrent::Actor::Reference
      end

      BitcoinEvent = Algebrick.atom
      BitcoinFundingPublishFailed = Algebrick.atom
      BitcoinFundingDepthok = Algebrick.atom
      BitcoinFundingDeeplyburied = Algebrick.atom
      BitcoinFundingLost = Algebrick.atom
      BitcoinFundingTimeout = Algebrick.atom
      BitcoinFundingSpent = Algebrick.atom
      BitcoinOutputSpent = Algebrick.atom
      BitcoinTxConfirmed = Algebrick.type do
        fields! tx: Bitcoin::Tx
      end
      BitcoinFundingExternalChannelSpent = Algebrick.type do
        fields! short_channel_id: Numeric
      end
      BitcoinParentTxConfirmed = Algebrick.type do
        fields! child_tx: Bitcoin::Tx
      end

      Data = Algebrick.type do
        DataWaitForOpenChannel = type do
          fields  init_fundee: InputInitFundee
        end
        DataWaitForAcceptChannel = type do
          fields  init_funder: InputInitFunder,
                  last_sent: OpenChannel
        end
        DataWaitForFundingCreated = type do
          fields  temporary_channel_id: String,
                  local_param: LocalParam,
                  remote_param: RemoteParam,
                  funding_satoshis: Numeric,
                  push_msat: Numeric,
                  initial_feerate_per_kw: Numeric,
                  remote_first_per_commitment_point: String,
                  channel_flags: Numeric,
                  last_sent: AcceptChannel
        end
        DataWaitForFundingInternal = type do
          fields  temporary_channel_id: String,
                  local_param: LocalParam,
                  remote_param: RemoteParam,
                  funding_satoshis: Numeric,
                  push_msat: Numeric,
                  initial_feerate_per_kw: Numeric,
                  remote_first_per_commitment_point: String,
                  last_sent: OpenChannel
        end
        DataWaitForFundingSigned = type do
          fields  channel_id: String,
                  local_param: LocalParam,
                  remote_param: RemoteParam,
                  funding_tx: Bitcoin::Tx,
                  local_spec: Lightning::Transactions::CommitmentSpec,
                  local_commit_tx: TransactionWithUtxo,
                  remote_commit: RemoteCommit,
                  channel_flags: Numeric,
                  last_sent: FundingCreated
        end
        DataWaitForFundingConfirmed = type do
          fields  commitments: Commitments,
                  deferred: Algebrick::Maybe[FundingLocked],
                  last_sent: type { variants FundingCreated, FundingSigned }
        end
        DataWaitForFundingLocked = type do
          fields  commitments: Commitments,
                  short_channel_id: Numeric,
                  last_sent: FundingLocked
        end
        DataNormal = type do
          fields  commitments: Commitments,
                  short_channel_id: Numeric,
                  buried: Numeric,
                  channel_announcement: Algebrick::Maybe[ChannelAnnouncement],
                  channel_update: ChannelUpdate,
                  local_shutdown: Algebrick::Maybe[Shutdown],
                  remote_shutdown: Algebrick::Maybe[Shutdown]
        end

        DataShutdown = type do
          fields  commitments: Commitments,
                  local_shutdown: Shutdown,
                  remote_shutdown: Shutdown
        end
        DataNegotiating = type do
          fields  commitments: Commitments,
                  local_shutdown: Shutdown,
                  remote_shutdown: Shutdown,
                  closing_tx_proposed: Array,
                  best_unpublished_closing_tx_opt: Algebrick::Maybe[Bitcoin::Tx]
        end
        DataClosing = type do
          fields  commitments: Commitments,
                  mutual_close_proposed: Array,
                  mutual_close_published: Array,
                  local_commit_published: Algebrick::Maybe[LocalCommitPublished],
                  remote_commit_published: Algebrick::Maybe[RemoteCommitPublished],
                  next_remote_commit_published: Algebrick::Maybe[RemoteCommitPublished],
                  future_remote_commit_published: Algebrick::Maybe[RemoteCommitPublished],
                  revoked_commit_published: Array
        end
        DataWaitForRemotePublishFutureCommitment = type do
          fields  commitments: Commitments,
                  remote_channel_reestablish: ChannelReestablish
        end

        variants  DataWaitForOpenChannel,
                  DataWaitForAcceptChannel,
                  DataWaitForFundingCreated,
                  DataWaitForFundingInternal,
                  DataWaitForFundingSigned,
                  DataWaitForFundingConfirmed,
                  DataWaitForFundingLocked,
                  DataNormal,
                  DataShutdown,
                  DataNegotiating,
                  DataClosing,
                  DataWaitForRemotePublishFutureCommitment
      end

      module DataWaitForFundingConfirmed
        include HasCommitments

        def status
          'opening'
        end

        def self.load(payload)
          _type, rest = payload.unpack('Ca*')
          commitments, rest = Commitments.load(rest)
          maybe, rest = rest.unpack('Ca*')
          if maybe
            deferred, rest = FundingLocked.load(rest)
          else
            deferred = Algebrick::None
          end
          last_sent_type, rest = rest.unpack('na*')
          if last_sent_type == FundingCreated.to_type
            last_sent, rest = FundingCreated.load(rest)
          else
            last_sent, rest = FundingSigned.load(rest)
          end
          [new(commitments, deferred, last_sent), rest]
        end

        def to_payload
          payload = +''
          payload << [1].pack('C')
          payload << self[:commitments].to_payload
          if self[:deferred].is_a? Algebrick::None
            payload << [0].pack('C')
          else
            payload << [1].pack('C')
            payload << self[:deferred].value.to_payload
          end
          payload << self[:last_sent].to_payload
          payload
        end
      end

      module DataWaitForFundingLocked
        include HasCommitments

        def status
          'opening'
        end

        def self.load(payload)
          _type, rest = payload.unpack('Ca*')
          [new, rest]
        end

        def to_payload
          payload = +''
          payload << [2].pack('C')
          payload << self[:commitments].to_payload
          payload << [self[:short_channel_id]].pack('q>')
          payload << self[:last_sent].to_payload
          payload
        end
      end

      module DataNormal
        include HasCommitments

        def shutting_down?
          self[:local_shutdown].maybe || self[:remote_shutdown].maybe
        end

        def copy(
          commitments: self[:commitments],
          short_channel_id: self[:short_channel_id],
          buried: self[:buried],
          channel_announcement: self[:channel_announcement],
          channel_update: self[:channel_update],
          local_shutdown: self[:local_shutdown],
          remote_shutdown: self[:remote_shutdown]
        )
          DataNormal[
            commitments,
            short_channel_id,
            buried,
            channel_announcement,
            channel_update,
            local_shutdown,
            remote_shutdown
          ]
        end

        def status
          self[:buried] == 1 ? 'open' : 'opening'
        end

        def self.load(payload)
          _type, rest = payload.unpack('Ca*')
          commitments, rest = Commitments.load(rest)
          short_channel_id, rest = rest.unpack('q>a*')
          buried, rest = rest.unpack('Ca*')
          len, rest = rest.unpack('na*')
          if len == 0
            channel_announcement = Algebrick::None
          else
            channel_announcement = Lightning::Wire::LightningMessages::ChannelAnnouncement.load(rest[0...len])
            channel_announcement = Algebrick::Some[Lightning::Wire::LightningMessages::ChannelAnnouncement][channel_announcement]
            rest = rest[len..-1]
          end

          len, rest = rest.unpack('na*')
          channel_update = Lightning::Wire::LightningMessages::ChannelUpdate.load(rest[0...len])
          rest = rest[len..-1]

          len, rest = rest.unpack('na*')
          if len == 0
            local_shutdown = Algebrick::None
          else
            local_shutdown, rest = Lightning::Wire::LightningMessages::Shutdown.load(rest)
          end
          len, rest = rest.unpack('na*')
          if len == 0
            remote_shutdown = Algebrick::None
          else
            remote_shutdown, rest = Lightning::Wire::LightningMessages::Shutdown.load(rest)
          end
          [new(commitments, short_channel_id, buried, channel_announcement, channel_update, local_shutdown, remote_shutdown), rest]
        end

        def to_payload
          payload = +''
          payload << [3].pack('C')
          payload << self[:commitments].to_payload
          payload << [self[:short_channel_id]].pack('q>')
          payload << [self[:buried]].pack('C')
          if self[:channel_announcement].is_a? Algebrick::None
            payload << [0].pack('n')
          else
            channel_announcement = self[:channel_announcement].value.to_payload
            payload << [channel_announcement.bytesize].pack('n')
            payload << self[:channel_announcement].value.to_payload
          end
          payload << [self[:channel_update].to_payload.bytesize].pack('n')
          payload << self[:channel_update].to_payload
          if self[:local_shutdown].is_a? Algebrick::None
            payload << [0].pack('n')
          else
            payload << self[:local_shutdown].value.to_payload
          end
          if self[:remote_shutdown].is_a? Algebrick::None
            payload << [0].pack('n')
          else
            payload << self[:remote_shutdown].value.to_payload
          end
          payload
        end
      end

      module DataShutdown
        include HasCommitments

        def status
          'closing'
        end

        def to_payload
          ''
        end
      end

      module DataNegotiating
        include HasCommitments

        def status
          'closing'
        end

        def to_payload
          ''
        end
      end

      module DataClosing
        include HasCommitments

        def status
          'closing'
        end

        def to_payload
          ''
        end
      end

      module DataWaitForRemotePublishFutureCommitment
        include HasCommitments

        def status
          'closing'
        end

        def to_payload
          ''
        end
      end

      module Commitments
        def has_no_pending_htlcs?
          self[:local_commit][:spec][:htlcs].empty? &&
          self[:remote_commit][:spec][:htlcs].empty? &&
          self[:remote_next_commit_info].is_a?(String)
        end

        def copy(
          local_commit: self[:local_commit],
          remote_commit: self[:remote_commit],
          local_changes: self[:local_changes],
          remote_changes: self[:remote_changes],
          local_next_htlc_id: self[:local_next_htlc_id],
          remote_next_htlc_id: self[:remote_next_htlc_id],
          origin_channels: self[:origin_channels],
          remote_next_commit_info: self[:remote_next_commit_info],
          remote_per_commitment_secrets: self[:remote_per_commitment_secrets]
        )
          Commitments[
            self[:local_param],
            self[:remote_param],
            self[:channel_flags],
            local_commit,
            remote_commit,
            local_changes,
            remote_changes,
            local_next_htlc_id,
            remote_next_htlc_id,
            origin_channels,
            remote_next_commit_info,
            self[:commit_input],
            remote_per_commitment_secrets,
            self[:channel_id]
          ]
        end

        def self.load(payload)
          local_param, rest = LocalParam.load(payload)
          remote_param, rest = RemoteParam.load(rest)
          channel_flags, rest = rest.unpack('na*')
          local_commit, rest = LocalCommit.load(rest)
          remote_commit, rest = RemoteCommit.load(rest)
          local_changes, rest = LocalChanges.load(rest)
          remote_changes, rest = RemoteChanges.load(rest)
          local_next_htlc_id, rest = rest.unpack('q>a*')
          remote_next_htlc_id, rest = rest.unpack('q>a*')
          len, rest = rest.unpack('na*')
          origin_channels = if len > 0
            origin_channels, rest = rest.unpack("H#{2 * len}a*")
            JSON.parse(origin_channels.htb)
          else
            {}
          end
          type, rest = rest.unpack('Ca*')
          if type == 0
            remote_next_commit_info, rest = WaitingForRevocation.load(rest)
          else
            len, rest = rest.unpack('na*')
            remote_next_commit_info, rest = rest.unpack("H#{2 * len}a*")
          end
          commit_input, rest = Lightning::Transactions::Utxo.load(rest)
          len, rest = rest.unpack('na*')
          remote_per_commitment_secrets_as_hex, rest = rest.unpack("H#{64 * len}a*")
          remote_per_commitment_secrets = (0..(len - 1)).map do |i|
            remote_per_commitment_secrets_as_hex[i..(i + 64)]
          end
          channel_id, rest = rest.unpack('H64a*')
          commiemtns = new(
            local_param,
            remote_param,
            channel_flags,
            local_commit,
            remote_commit,
            local_changes,
            remote_changes,
            local_next_htlc_id,
            remote_next_htlc_id,
            origin_channels,
            remote_next_commit_info,
            commit_input,
            remote_per_commitment_secrets,
            channel_id
          )
          [commiemtns, rest]
        end

        def to_payload
          payload = +''
          payload << self[:local_param].to_payload
          payload << self[:remote_param].to_payload
          payload << [self[:channel_flags]].pack('n')
          payload << self[:local_commit].to_payload
          payload << self[:remote_commit].to_payload
          payload << self[:local_changes].to_payload
          payload << self[:remote_changes].to_payload
          payload << [self[:local_next_htlc_id]].pack('q>')
          payload << [self[:remote_next_htlc_id]].pack('q>')
          json = self[:origin_channels].to_json
          payload << [json.length].pack('n')
          payload << json
          if self[:remote_next_commit_info].is_a? WaitingForRevocation
            payload << [0].pack('C')
            payload << self[:remote_next_commit_info].to_payload
          else
            payload << [1].pack('C')
            len = self[:remote_next_commit_info].length
            payload << [len].pack('C')
            payload << self[:remote_next_commit_info].htb
          end
          payload << self[:commit_input].to_payload
          payload << [self[:remote_per_commitment_secrets].length].pack('n')
          payload << self[:remote_per_commitment_secrets].join('').htb
          payload << self[:channel_id].htb
          payload
        end
      end

      InputRestored = Algebrick.type do
        fields! data: HasCommitments
      end
    end
  end
end
