class Bankstatements::Response < ActiveRecord::Base
  self.table_name = "bankstatement_responses"
  belongs_to :request, dependent: :destroy, inverse_of: :response

  serialize :headers
  serialize :json

  def initialize(options={})
    if options[:headers]
      options[:headers] = (options[:headers].to_h rescue {}) unless options[:headers].is_a?(Hash)
    end
    super(options)
  end

  def to_hash
    raise "No json to construct hash from" unless self.json.present?
    self.json.to_h
  end

  def error
    self.to_hash unless self.success?
  end

end
