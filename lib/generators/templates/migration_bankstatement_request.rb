class CreateBankstatementRequest < ActiveRecord::Migration
  def self.up
  create_table :bankstatement_requests do |t|
    t.integer :ref_id
    t.text :json
    # TODO
    t.timestamps
  end
  end

  def self.down
    drop_table :bankstatement_requests
  end
end
