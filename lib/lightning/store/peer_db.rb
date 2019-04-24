# frozen_string_literal: true

module Lightning
  module Store
    class PeerDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists peers (
            node_id text not null primary key,
            host text not null,
            port int not null,
            connected int not null
          )
        SQL
      end

      def insert_or_update(node_id, host: nil, port: nil)
        db.execute(
          'INSERT INTO peers (node_id, host, port, connected) VALUES (?, ?, ?, ?)',
          [node_id, host, port, 0]
        )
      rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE peers SET host = ?, port = ?, connected = ? WHERE node_id = ?',
          [host, port, 0, node_id]
        )
      end

      def update(node_id, connected: nil)
        db.execute(
          'UPDATE peers SET connected = ? WHERE node_id = ?',
          [connected, node_id]
        )
      rescue SQLite3::ConstraintException => _
      end

      def delete(node_id)
        db.execute('DELETE FROM peers WHERE node_id = ?', [node_id])
      end

      def find(node_id)
        db.execute('SELECT * FROM peers WHERE node_id = ?', [node_id]).first
      end

      def all
        db.execute('SELECT * FROM peers')
      end

      def connected
        db.execute('SELECT * FROM peers WHERE connected = 1')
      end

      def clear
        db.execute('DELETE FROM peers')
      end
    end
  end
end
