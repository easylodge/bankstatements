class CreateProvisoQueries < ActiveRecord::Migration
  def self.up
    create_table :proviso_queries do |t|
      t.integer :ref_id
      t.text :access
      t.text :accounts
      t.string :error
      t.timestamps
    end
  end

  def self.down
    drop_table :proviso_queries
  end
end
