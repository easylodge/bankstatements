require 'spec_helper'

describe Bankstatements::Request do
  it { should have_one(:response).dependent(:destroy) }

  it { should validate_presence_of(:access) }
  it { should validate_presence_of(:enquiry) }

  it { should respond_to(:ref_id) }
  it { should respond_to(:json) }
  it { should respond_to(:access) }
  it { should respond_to(:enquiry) }
  it { should respond_to(:created_at) }
  it { should respond_to(:updated_at) }


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
    @request = Bankstatements::Request.new(access: @access_hash, enquiry: @enquiry_hash)

  end

  describe ".json" do
    it "returns nil if no enquiry is available" do
      @request.enquiry = nil
      expect(@request.json).to eq(nil)
    end

    it "converts the enquiry values into a json structure" do
      expect(@request.json).to eq(@enquiry_hash.to_json)
    end
  end

  describe ".post" do
    before(:each) do
      # prevent calling the actual URL, we jsut harvest the opts we pass in so we can invetigate them if we want
      allow(HTTParty).to receive(:post).with(any_args){|u, h| [u, h]}
    end

    context "when invalid" do
      it "raises exception if there is no request json" do
        @request.enquiry = nil
        expect{@request.post}.to raise_error("No request json")
      end

      it "raises exception if there is no api_key" do
        @request.access[:api_key] = nil
        expect{@request.post}.to raise_error("No API KEY provided")
      end

      it "raises exception if there is no api url" do
        @request.access[:url] = nil
        expect{@request.post}.to raise_error("No API URL provided")
      end
    end

    context "when valid" do
      context "with headers" do
        before(:each) do
          # The structure here is dependent on our mock for the HTTParty message way at the top
          @headers = @request.post.last[:headers]
        end

        it "sets X-API-KEY" do
          expect(@headers['X-API-KEY'].present?).to eq(true)
        end

        it "sets X-OUTPUT-VERSION"  do
          expect(@headers['X-OUTPUT-VERSION']).to eq('20170401')  #to 20170401
        end

        it "sets Content-Type"  do
          expect(@headers['Content-Type']).to eq('application/json')  #to application/json
        end
        it "sets Accept" do
          expect(@headers['Accept']).to eq('application/json')   #to application/json
        end
      end

      it "posts the request" do
        expect(HTTParty).to receive(:post)
        @request.post
      end
    end
  end

end
