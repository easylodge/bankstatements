require 'spec_helper'

describe Bankstatements::Response do
  it { should belong_to(:request).dependent(:destroy) }

  describe ".initialize" do
    it "converts :header to a hash" do
      not_a_hash = OpenStruct.new
      expect(not_a_hash).to receive(:to_h)
      Bankstatements::Response.new(headers: not_a_hash)
    end
  end

  describe ".to_hash" do
    it "returns an error if there is no json"
    it "returns a hash of the json"
  end

  describe ".error" do
    it "returns the json unless the response success"
    it "returns nil if the reponse was success"
  end
end
