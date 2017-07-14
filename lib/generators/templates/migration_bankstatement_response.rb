class CreateBankstatementResponse < ActiveRecord::Migration
  def self.up
  create_table :bankstatement_responses  do |t|
    t.text :headers
    t.integer :code
    t.text :json
    t.boolean :success
    # TODO
    t.timestamps
  end
  end

  def self.down
    drop_table :bankstatement_responses
  end
end
