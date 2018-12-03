# frozen_string_literal: true

module Lightning
  module Store
    class ChannelDb < Sqlite
      def setup
        db.execute <<-SQL
          create table if not exists channels (
            channel_id text not null primary key,
            data text not null
          )
        SQL
      end

      def insert_or_update(data)
        db.execute(
          'INSERT INTO channels (channel_id, data) VALUES (?, ?)',
          [data.channel_id, data.to_payload.bth]
        )
      rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE channels set data = ? WHERE channel_id = ?',
          [data.to_payload.bth, data.channel_id]
        )
      end

      def remove(channel_id)
        db.execute(
          'DELETE FROM channels WHERE channel_id = ?',
          [channel_id]
        )
      end
    end
  end
end
