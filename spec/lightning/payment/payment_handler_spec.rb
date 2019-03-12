# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Payment::PaymentHandler do
  describe '#on_message' do
    subject do
      payment_handler << message
      payment_handler.ask(:await).wait
    end

    let(:private_key) { '41' * 32 }
    let(:node_param) { build(:node_param, private_key: private_key) }
    let(:context) { build(:context, node_params: node_param) }
    let(:payment_handler) { described_class.spawn(:payment_handler, context) }

    describe 'with ReceivePayment' do
      let(:message) { build(:receive_payment).get }

      it do
        subject
        expect(payment_handler.ask!(:preimages).size).to eq 1
      end
    end

    describe 'with UpdateAddHtlc' do
      it do
        payment_hash = payment_handler.ask!(build(:receive_payment).get).payment_hash
        message = build(:update_add_htlc, payment_hash: payment_hash)
        expect do
          payment_handler << message
          payment_handler.ask(:await).wait
        end.to change { payment_handler.ask!(:preimages).size }.from(1).to(0)
      end
    end
  end
end
