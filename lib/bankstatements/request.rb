class Bankstatements::Request < ActiveRecord::Base
  self.table_name = "bankstatement_requests"
  has_one :response, dependent: :destroy, inverse_of: :request
  serialize :access
  serialize :enquiry

  validates :access, presence: true
  validates :enquiry, presence: true

  def json
    return nil unless self.enquiry.present?
    #TODO: turn @enquiry into json payload for request
    enquiry.to_json
  end

  def post
    raise "No request json" unless self.json
    raise "No API KEY provided" unless self.access[:api_key].present?
    raise "No API URL provided" unless self.access[:url].present?

    headers = {
      'X-API-KEY' => self.access[:api_key],
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-OUTPUT-VERSION' => '20170401'
    }

    HTTParty.post(self.access[:url], :body => self.json, :headers => headers)
  end

end
