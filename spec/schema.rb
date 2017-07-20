ActiveRecord::Schema.define do
  self.verbose = false

  create_table :bankstatement_queries do |t|
    t.integer :ref_id
    t.text :access
    t.text :accounts
    t.string :error
    t.timestamps
  end
end
