# frozen_string_literal: true

module Lightning
  module Store
    autoload :ChannelDb, 'lightning/store/channel_db'
    autoload :InvoiceDb, 'lightning/store/invoice_db'
    autoload :NodeDb, 'lightning/store/node_db'
    autoload :PaymentDb, 'lightning/store/payment_db'
    autoload :PeerDb, 'lightning/store/peer_db'
    autoload :Sqlite, 'lightning/store/sqlite'
    autoload :UtxoDb, 'lightning/store/utxo_db'
  end
end
