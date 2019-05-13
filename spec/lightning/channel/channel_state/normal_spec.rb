# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Channel::ChannelState::Normal do
  let(:state) { described_class.new(channel, channel_context) }
  let(:ln_context) { Lightning::Context.new(spv) }
  let(:channel_context) { Lightning::Channel::ChannelContext.new(ln_context, forwarder, remote_node_id) }
  let(:channel) { DummyActor.spawn(:channel) }
  let(:forwarder) { DummyActor.spawn(:forwarder) }
  let(:temporary_channel_id) { '00' * 32 }
  let(:remote_node_id) { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
  let(:spv) { create_test_spv }

  before { spv.stub(:block_height).and_return(100) }

  describe '#origin' do
    subject { state.origin(command) }

    let(:state) { described_class.new(channel, channel_context) }

    context 'when command from local' do
      let(:command) { build(:command_add_htlc, :local).get }

      it { expect(subject).to be_a Lightning::Payment::Relayer::Local }
    end
    context 'when command from remote' do
      let(:command) { build(:command_add_htlc, :remote).get }

      it { expect(subject).to be_a Lightning::Payment::Relayer::Relayed }
    end
  end

  describe '#message' do
    subject { state.next(message, data) }

    let(:commitment) { build(:commitment, :funder).get }
    let(:data) do
      Lightning::Channel::Messages::DataNormal[
        temporary_channel_id: '36155cae4b48d26ab48aa6ac239da93219615cb8dd846d2a2abeb455af9b3357',
        commitments: commitment,
        short_channel_id: 1,
        buried: 1,
        channel_announcement: Algebrick::None,
        channel_update: build(:channel_update),
        local_shutdown: Algebrick::None,
        remote_shutdown: Algebrick::None
      ]
    end

    before { allow(Lightning::Transactions).to receive(:add_sigs).and_return(Bitcoin::Tx.new) }

    describe 'with CommandAddHtlc' do
      let(:message) { build(:command_add_htlc).get }

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with UpdateAddHtlc' do
      let(:message) { build(:update_add_htlc, id: 2) }

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandFulfillHtlc' do
      let(:message) { build(:command_fulfill_htlc).get }
      let(:commitment) do
        build(:commitment, :funder, :has_local_received_htlcs, :has_remote_offered_htlcs, remote_next_commit_info: '').get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with UpdateFulfillHtlc' do
      let(:message) { build(:update_fulfill_htlc) }
      let(:commitment) do
        build(
          :commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs,
          origin_channels: { 0 => Lightning::Payment::Relayer::Local },
          remote_next_commit_info: ''
        ).get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandFailHtlc' do
      let(:message) { build(:command_fail_htlc).get }
      let(:commitment) do
        build(:commitment, :funder, :has_local_received_htlcs, :has_remote_offered_htlcs, remote_next_commit_info: '').get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with UpdateFailHtlc' do
      let(:message) { build(:update_fail_htlc) }
      let(:commitment) do
        build(
          :commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs,
          origin_channels: { 0 => Lightning::Payment::Relayer::Local }
        ).get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandFailMalformedHtlc' do
      let(:message) { build(:command_fail_malformed_htlc).get }
      let(:commitment) do
        build(:commitment, :funder, :has_local_received_htlcs, :has_remote_offered_htlcs, remote_next_commit_info: '').get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with UpdateFailMalformedHtlc' do
      let(:message) { build(:update_fail_malformed_htlc) }
      let(:commitment) do
        build(
          :commitment, :funder, :has_local_offered_htlcs, :has_remote_received_htlcs,
          origin_channels: { 0 => Lightning::Payment::Relayer::Local }
        ).get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandUpdateFee' do
      let(:message) { build(:command_update_fee).get }
      let(:commitment) do
        build(:commitment, :funder, :has_local_received_htlcs, :has_remote_offered_htlcs, remote_next_commit_info: '').get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with UpdateFee' do
      let(:message) { build(:update_fee) }
      let(:commitment) { build(:commitment, :fundee).get }

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandSignature' do
      let(:message) { build(:command_signature).get }

      context 'when remote_next_commit_info is WaitingForRevocation' do
        it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
        it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
      end

      context 'when remote_next_commit_info is String' do
        let(:commitment) do
          build(:commitment,
            :funder,
            remote_next_commit_info: '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486',
            local_change: build(:local_change, :has_local_change).get
          ).get
        end

        it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
        it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
      end
    end

    describe 'with CommitmentSigned' do
      let(:message) { build(:commitment_signed, htlc_signature: htlc_signature) }
      let(:htlc_signature) { [] }
      let(:update) { build(:update_add_htlc) }
      let(:local_change) { build(:local_change, acked: [update]).get }
      let(:commitment) do
        build(:commitment, :funder, local_change: local_change).get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with RevokeAndAck' do
      let(:message) { build(:revoke_and_ack) }
      let(:remote_commit) do
        build(
          :remote_commit,
          remote_per_commitment_point: '025f7117a78150fe2ef97db7cfc83bd57b2e2c0d0dd25eaf467a4a1c2a45ce1486'
        ).get
      end
      let(:commitment) do
        build(
          :commitment,
          :funder,
          :has_local_received_htlcs,
          :has_remote_offered_htlcs,
          remote_commit: remote_commit,
          remote_next_commit_info: build(:waiting_for_revocation).get
        ).get
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
    end

    describe 'with CommandClose' do
      let(:script_pubkey) { '0014ccf1af2f2aabee14bb40fa3851ab2301de843110' }
      let(:message) { Lightning::Channel::Messages::CommandClose[Algebrick::Some[String][script_pubkey]] }

      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
      it { expect(subject[1][:local_shutdown]).to be_a Algebrick::Some[Lightning::Wire::LightningMessages::Shutdown] }
    end

    describe 'with Shutdown' do
      let(:message) { build(:shutdown) }

      context 'has no pending htlcs' do
        let(:commitment) { build(:commitment, :funder, remote_next_commit_info: '').get }

        it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Negotiating }
        it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNegotiating }
        it { expect(subject[1][:closing_tx_proposed]).not_to be_empty }
      end
      context 'has pending htlcs' do
        let(:commitment) { build(:commitment, :has_local_received_htlcs, :has_remote_offered_htlcs).get }

        it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Shutdowning }
        it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataShutdown }
      end
    end

    describe 'with WatchEventConfirmed' do
      let(:message) do
        Lightning::Blockchain::Messages::WatchEventConfirmed[
          'deeply_confirmed', 4321, 9
        ]
      end

      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
      it 'broadcast ShortChannelIdAssigned' do
        expect(channel_context.broadcast).to receive(:<<).with(Lightning::Channel::Events::ShortChannelIdAssigned)
        subject
        channel_context.broadcast.ask(:await).wait
      end

      it 'forward AnnouncementSignature' do
        expect(forwarder).to receive(:<<).with(Lightning::Wire::LightningMessages::AnnouncementSignatures)
        subject
        forwarder.ask(:await).wait
      end
    end

    describe 'with AnnouncementSignatures' do
      let(:message) { build(:announcement_signatures) }
      it { expect(subject[0]).to be_a Lightning::Channel::ChannelState::Normal }
      it { expect(subject[1]).to be_a Lightning::Channel::Messages::DataNormal }
      it { expect(subject[1][:channel_announcement]).to be_a Algebrick::Some[Lightning::Wire::LightningMessages::ChannelAnnouncement] }
    end
  end
end
