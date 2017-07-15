require 'spec_helper'

describe Bankstatements::Request, focus: true do
  it { should have_one(:response).dependent(:destroy) }

  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:enquiry) }

  before(:each) do
    @config = YAML.load_file('dev_config.yml')
    # @config = {url: "url", apy_key: "api_key"}
    @access_hash =
      {
        :url => @config["url"],
        :api_key => @config["api_key"]
      }

    @enquiry_hash = {
      :foo => "foo",
      :bar => "bar"
    }

    @request = Bankstatements::Request.new(access: @access_hash, enquiry: @enquiry_hash)
  end

  describe ".json" do
    it "converts the enquiry values into a json structure"
  end

  describe ".post" do
    context "when invalid" do
      it "raises exception if there is no json" do
        @request.json = nil
        expect(@request.error.message).to eq("No request json")
      end

      it "raises exception if there is no api_key" do
        @request.access[:api_key] = nil
        expect(@request.error.message).to eq("No API KEY provided")
      end

      it "raises exception if there is no api url" do
        @request.access[:url] = nil
        expect(@request.error.message).to eq("No API URL provided")
      end
    end

    context "when valid" do
      before(:each) do
        header = @request.post
      end

      it "sets the X-API-KEY header" do
        expect(header['X-API-KEY'].present?).to eq(true)
      end

      it "sets the X-OUTPUT-VERSION header"  do
        expect(header['X-OUTPUT-VERSION']).to eq('20170401')  #to 20170401
      end

      it "sets the Content-Type header"  do
        expect(header['Content-Type']).to eq('application/json')  #to application/json
      end
      it "sets the Accept header" do
        expect(header['Accept']).to eq('application/json')   #to application/json
      end

      it "posts the request" #mock the post, just check that it's called
    end


  end

end
