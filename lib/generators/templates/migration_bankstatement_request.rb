class CreateBankstatementRequest < ActiveRecord::Migration
  def self.up
    create_table :bankstatement_queries do |t|
      t.integer :ref_id
      t.text :access
      t.text :accounts
      t.timestamps
    end
  end

  def self.down
    drop_table :bankstatement_queries
  end
end
