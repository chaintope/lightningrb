# frozen_string_literal: true

require 'sqlite3'

module Lightning
  module Store
    class Sqlite
      attr_reader :db

      def initialize(path)
        @db = SQLite3::Database.new(path)
        setup
      end

      def setup
        raise NotImplementedError
      end
    end
  end
end
