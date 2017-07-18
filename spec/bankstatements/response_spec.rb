require 'spec_helper'

describe Bankstatements::Response do
  it { should belong_to(:request).dependent(:destroy) }

  it { should respond_to(:request_id) }
  it { should respond_to(:code) }
  it { should respond_to(:json) }
  it { should respond_to(:success) }
  it { should respond_to(:headers) }
  it { should respond_to(:created_at) }
  it { should respond_to(:updated_at) }

  before(:each) do
    @response = Bankstatements::Response.new()
  end

  describe ".initialize" do
    it "converts :headers to a hash" do
      response = Bankstatements::Response.new(headers: "not_a_hash")
      expect(response.headers).to be_a(Hash)
    end

    it "sets :headers to a hash" do
      response = Bankstatements::Response.new(headers: {'find': 'me'})
      expect(response.headers).to eq({'find': 'me'})
    end
  end

  describe ".to_hash" do
    it "returns an error if there is no json" do
      @response.json = nil
      expect{@response.to_hash}.to raise_error("No json to construct hash from")
    end

    it "returns a hash of the json" do
      @response.json = JSON.parse({example: 'json'}.to_json)
      expect(@response.to_hash).to eq(@response.json.to_h)
    end
  end

  describe ".error" do
    before(:each) do
      @response.json = JSON.parse({error: 'example'}.to_json)
      expect(@response.to_hash).to be_present
    end

    it "returns the error hash unless the response success" do
      @response.success = false
      expect(@response.error).to eq(@response.to_hash)
    end

    it "returns nil if the reponse was success" do
      @response.success = true
      expect(@response.error).to eq(nil)
    end

  end
end
