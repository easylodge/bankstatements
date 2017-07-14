require 'spec_helper'

describe Bankstatement::Request do
  it { should have_one(:response).dependent(:destroy) }

  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:enquiry) }

  before(:each) do
    @config = YAML.load_file('dev_config.yml')
    @access_hash =
      {
        :url => @config["url"],
        :api_key => @config["api_key"]
      }

    @enquiry_hash = {
      :foo => "foo",
      :bar => "bar"
    }

    @request = Bankstatement::Request.new(access: @access_hash, enquiry: @enquiry_hash)
  end

  describe ".json" do
    it "converts the enrquiry values into a json structure"
  end

  describe ".post" do
    context "when invalid" do
      it "raises exception if there is no json"
      it "raises exception if there is no api_key"
      it "raises exception if there is no api url"
    end

    context "when valid" do
      it "sets the X-API-KEY header"
      it "sets the X-OUTPUT-VERSION header" #to 20170401
      it "sets the Content-Type header" #to application/json
      it "sets the Accept header" #to application/json
      it "posts the request" #mock the post, just check that it's called
    end


  end

end
