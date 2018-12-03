# frozen_string_literal: true

module Lightning
  module Store
    class PaymentDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists payments (
            payment_hash text not null primary key,
            amount_msat integer not null,
            timestamp integer not null
          )
        SQL
      end
    end
  end
end
