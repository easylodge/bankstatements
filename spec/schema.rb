ActiveRecord::Schema.define do
self.verbose = false

  create_table :bankstatement_requests do |t|
    t.integer :ref_id
    t.text :json
    # TODO
    t.timestamps
  end

  create_table :bankstatement_responses  do |t|
    t.text :headers
    t.integer :code
    t.text :json
    t.boolean :success
    # TODO
    t.timestamps
  end
end