module Proviso
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../../templates", __FILE__)
      desc "Sets up the Proviso migrations File"

      def self.next_migration_number(dirname)
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      end

      def create_migration_file
        #copy migration
        migration_template "migration_proviso_queries.rb", "db/migrate/create_proviso_queries.rb"
      end
    end
  end
end
