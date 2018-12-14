# frozen_string_literal: true

FactoryBot.define do
  factory(:receive_payment, class: 'FactoryBotWrapper') do
    amount_msat { 10_000_000 }
    description { 'ナンセンス1杯' }
    initialize_with do
      new(Lightning::Payment::Messages::ReceivePayment[amount_msat, description])
    end
  end
end
