module Bankstatement
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../../templates", __FILE__)
      desc "Sets up the Bankstatement migrations File"

      def self.next_migration_number(dirname)
        Time.new.utc.strftime("%Y%m%d%H%M%S")
      end

      def create_migration_file
        #copy migration
        migration_template "migration_bankstatement_query.rb", "db/migrate/create_bankstatement_query.rb"
      end
    end
  end
end
