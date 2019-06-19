# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Router::Router do

  let(:context) { build(:context) }
  let(:router) { Lightning::Router::Router.spawn(:router, context) }

  let(:sender) { spawn_dummy_relayer }

  describe '#on_message' do
    context 'with RouteRequest message' do
      subject do
        sender.ask! [router, message]
      end

      let(:public_key0) { '02eec7245d6b7d2ccb30380bfbe2a3648cd7a942653f5aa340edcea1f283686619' }
      let(:public_key1) { '0324653eac434488002cc06bbfb7f10fe18991e35f9fe4302dbea6d2353dc0ab1c' }
      let(:public_key2) { '027f31ebc5462c1fdce1b737ecff52d37d75dea43ce11c74d25aa297165faa2007' }
      let(:public_key3) { '032c0b7cf95324a07d05398b240174dc0c2be444d96b159aa6c7f7b1e668680991' }
      let(:public_key4) { '02edabbd16b41c8371b92ef2f04c1185b4f03b6dcd52ba9b78d9d7c89c8f221145' }
      let(:source) { public_key0 }
      let(:target) { public_key4 }

      let(:message) { Lightning::Router::Messages::RouteRequest[public_key0, public_key4, [], []] }

      context "Route exists" do
        before do
          channel1 = build(:channel_announcement, short_channel_id: 0, node_id_1: public_key0, node_id_2: public_key1)
          expect(channel1).to receive(:valid_signature?).and_return(true)
          router << channel1
          router.ask(:await).wait

          channel2 = build(:channel_announcement, short_channel_id: 1, node_id_1: public_key1, node_id_2: public_key2)
          expect(channel2).to receive(:valid_signature?).and_return(true)
          router << channel2
          router.ask(:await).wait

          channel3 = build(:channel_announcement, short_channel_id: 2, node_id_1: public_key2, node_id_2: public_key3)
          expect(channel3).to receive(:valid_signature?).and_return(true)
          router << channel3
          router.ask(:await).wait

          channel4 = build(:channel_announcement, short_channel_id: 3, node_id_1: public_key3, node_id_2: public_key4)
          expect(channel4).to receive(:valid_signature?).and_return(true)
          router << channel4
          router.ask(:await).wait

          update1 = build(:channel_update,  short_channel_id: 0)
          expect(update1).to receive(:valid_signature?).and_return(true)
          router << update1
          router.ask(:await).wait

          update2 = build(:channel_update,  short_channel_id: 1)
          expect(update2).to receive(:valid_signature?).and_return(true)
          router << update2
          router.ask(:await).wait

          update3 = build(:channel_update,  short_channel_id: 2)
          expect(update3).to receive(:valid_signature?).and_return(true)
          router << update3
          router.ask(:await).wait

          update4 = build(:channel_update,  short_channel_id: 3)
          expect(update4).to receive(:valid_signature?).and_return(true)
          router << update4
          router.ask(:await).wait
        end

        it do
          expect(sender).to receive(:<<).with(Lightning::Router::Messages::RouteResponse)
          subject
          router.ask(:await).wait
        end
      end
    end
  end
end
