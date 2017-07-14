class Bankstatements::Response < ActiveRecord::Base
  self.table_name = "bankstatement_responses"
  belongs_to :request, dependent: :destroy, inverse_of: :response

  serialize :headers
  serialize :struct

  def initialize(options={})
    if options[:headers]
      options[:headers] = (options[:headers].to_h rescue {}) unless options[:headers].is_a?(Hash)
    end
    super(options)
  end

  def to_hash
    if self.json
      Hash.from_json(self.json)
    else
      "No hash was created because there was no json"
    end
  end

  def error
    self.json unless self.success?
  end

end
