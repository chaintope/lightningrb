# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Payment::PaymentInitiator do
  describe '#on_message' do
    subject do
      payment_handler << message
      payment_handler.ask(:await).wait
    end

    let(:node_param) { build(:node_param) }
    let(:context) { build(:context, node_params: node_param) }
    let(:payment_handler) { described_class.spawn(:payment_handler, node_param.node_id, context) }

    describe 'with SendPayment' do
      let(:message) { build(:send_payment).get }

      it do
        subject
        expect(payment_handler.ask!(:payments).size).to eq 1
        expect(payment_handler.ask!(:payments)).to eq( {'0000000000000000000000000000000000000000000000000000000000000000' => message})
      end
    end

    describe 'with PaymentSucceeded' do
      let(:send) { build(:send_payment).get }
      let(:message) { Lightning::Payment::Events::PaymentSucceeded[1_000_000, '00' * 32, '11' * 32 ,[]] }

      it do
        payment_handler << send
        subject
        expect(payment_handler.ask!(:payments).size).to eq 0
        expect(payment_handler.ask!(:payments).to_json).to eq '{}'
      end
    end
  end
end
