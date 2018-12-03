# frozen_string_literal: true

module Lightning
  module Store
    class PeerDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists peers (
            node_id text not null primary key,
            host text not null,
            port int not null
          )
        SQL
      end

      def insert_or_update(node_id, host, port: 9735)
        db.execute(
          'INSERT INTO peers (node_id, host, port) VALUES (?, ?, ?)',
          [node_id, host, port]
        )
      rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE peers SET host = ?, port = ? WHERE node_id = ?',
          [host, port, node_rgb_color]
        )
      end

      def delete(node_id)
        db.execute('DELETE FROM peers WHERE node_id = ?', [node_id])
      end

      def all
        db.execute('SELECT * FROM peers')
      end

      def clear
        db.execute('DELETE FROM peers')
      end
    end
  end
end
