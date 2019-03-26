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
        db.execute <<-SQL
          create table if not exists channel_updates (
            short_channel_id text not null primary key,
            data text not null
          )
        SQL
        db.execute <<-SQL
          create table if not exists channel_announcements (
            short_channel_id text not null primary key,
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

      def insert_or_update_channel_update(channel_update)
        db.execute(
          'INSERT INTO channel_updates (short_channel_id, data) VALUES (?, ?)',
          [channel_update.short_channel_id, channel_update.to_payload.bth]
        )
        rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE channel_updates set data = ? WHERE short_channel_id = ?',
          [channel_update.to_payload.bth, channel_update.short_channel_id]
        )
      end

      def insert_or_update_channel_announcement(channel_announcement)
        db.execute(
          'INSERT INTO channel_announcements (short_channel_id, data) VALUES (?, ?)',
          [channel_announcement.short_channel_id, channel_announcement.to_payload.bth]
        )
        rescue SQLite3::ConstraintException => _
        db.execute(
          'UPDATE channel_announcements set data = ? WHERE short_channel_id = ?',
          [channel_announcement.to_payload.bth, channel_announcement.short_channel_id]
        )
      end

      def all
        db.execute('SELECT * FROM channels')
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
