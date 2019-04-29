# frozen_string_literal: true

require 'spec_helper'

describe Lightning::Payment::PaymentHandler do
  describe '#load_invoices' do
    subject { payment_handler.load_invoices }

    let(:private_key) { '41' * 32 }
    let(:node_param) { build(:node_param, private_key: private_key) }
    let(:context) { build(:context, node_params: node_param) }
    let(:payment_handler) { described_class.new(context) }
    let(:preimage) { '00' * 32 }
    let(:payment_hash) { Bitcoin.sha256(preimage.htb).bth }
    let(:invoice) do
      Lightning::Invoice::Message.new.tap do |m|
        m.prefix = 'lnbc'
        m.amount = 500
        m.multiplier = ''
        m.timestamp = Time.now.to_i
        m.payment_hash = payment_hash
        m.sign(Bitcoin::Key.new(priv_key: private_key))
      end
    end

    before { context.invoice_db.insert(preimage, invoice) }

    it { expect(subject.size).to eq 1 }
    it { expect(subject[payment_hash]).to eq [preimage, invoice] }
  end

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

      it do
        expect { subject }.to change { context.invoice_db.all.size }.by(1)
      end
    end

    describe 'with UpdateAddHtlc' do
      let(:message) { build(:update_add_htlc, payment_hash: payment_hash) }
      let(:payment_hash) { payment_handler.ask!(build(:receive_payment).get).payment_hash }

      it do
        payment_hash
        expect { subject }.to change { payment_handler.ask!(:preimages).size }.by(-1)
      end

      it do
        payment_hash
        expect { subject }.to change { context.invoice_db.all.size }.by(-1)
      end
    end
  end
end
