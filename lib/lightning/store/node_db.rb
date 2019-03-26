# frozen_string_literal: true

module Lightning
  module Store
    class NodeDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists nodes (
            node_id text not null primary key,
            payload text
          )
        SQL
      end

      def insert(node_announcement)
        db.execute(
          'INSERT INTO nodes (node_id, payload) VALUES (?, ?)',
          [node_announcement.node_id, node_announcement.to_payload.bth]
        )
      end

      def update(node_announcement)
        db.execute(
          'UPDATE nodes SET payload = ? WHERE node_id = ?',
          [node_announcement.to_payload.bth, node_announcement.node_id]
        )
      end

      def destroy_by(node_id: nil)
        return unless node_id
        db.execute('DELETE FROM nodes WHERE node_id = ?', [node_id])
      end

      def find_by(node_id: nil)
        return [] unless node_id
        db.execute('SELECT payload FROM nodes WHERE node_id = ?', [node_id]).map do |record|
          Lightning::Wire::LightningMessages::NodeAnnouncement.load(record[0].htb)
        end
      end

      def all
        db.execute('SELECT payload FROM nodes').map do |record|
          Lightning::Wire::LightningMessages::NodeAnnouncement.load(record[0].htb)
        end
      end

      def clear
        db.execute('DELETE FROM nodes')
      end
    end
  end
end
