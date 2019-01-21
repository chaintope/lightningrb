# frozen_string_literal: true

FactoryBot.define do
  factory(:send_payment, class: 'FactoryBotWrapper') do
    amount_msat { 10_000_000 }
    payment_hash { '00' * 32 }
    target_node_id { '028d7500dd4c12685d1f568b4c2b5048e8534b873319f3a8daa612b469132ec7f7' }
    routes []
    final_cltv_expiry 144
    initialize_with do
      new(Lightning::Payment::Messages::SendPayment[amount_msat, payment_hash, target_node_id, routes, final_cltv_expiry])
    end
  end
end
