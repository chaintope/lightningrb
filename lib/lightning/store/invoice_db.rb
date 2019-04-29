# frozen_string_literal: true

module Lightning
  module Store
    class InvoiceDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists invoices (
            preimage text not null primary key,
            invoice text not null
          )
        SQL
      end

      def insert(preimage, invoice)
        db.execute(
          'INSERT INTO invoices (preimage, invoice) VALUES (?, ?)',
          [preimage, invoice.to_bech32]
        )
      end

      def delete(preimage)
        db.execute(
          'DELETE FROM invoices WHERE preimage = ?',
          [preimage]
        )
      end

      def all
        db.execute('SELECT * FROM invoices').map do |preimage, payload|
          [preimage, Lightning::Invoice.parse(payload)]
        end
      end
    end
  end
end
