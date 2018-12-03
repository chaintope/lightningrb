# frozen_string_literal: true

module Lightning
  module Store
    class UtxoDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists utxos(
            value bigint,
            script_pubkey text,
            txid text,
            idx int,
            redeem_script text,
            primary key (txid, idx)
          )
        SQL
      end

      def insert(txid, index, value, script_pubkey, redeem_script)
        db.execute(
          'INSERT INTO utxos (txid, idx, value, script_pubkey, redeem_script) VALUES (?, ?, ?, ?, ?)',
          [txid, index, value, script_pubkey, redeem_script]
        )
      rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE utxos SET value = ?, script_pubkey = ? , redeem_script = ? WHERE txid = ? AND IDX = ?',
          [value, script_pubkey, redeem_script, txid, index]
        )
      end

      def delete(txid, index)
        db.execute(
          'DELETE FROM utxos WHERE txid = ? AND idx = ?',
          [txid, index]
        )
      end

      def all
        rows = db.execute('SELECT txid, idx, value, script_pubkey, redeem_script FROM utxos')
        rows.map do |row|
          {
            txid: row[0],
            index: row[1].to_i,
            value: row[2].to_i,
            script_pubkey: row[3],
            redeem_script: row[4],
          }
        end
      end

      def clear
        db.execute('DELETE FROM utxos')
      end
    end
  end
end
