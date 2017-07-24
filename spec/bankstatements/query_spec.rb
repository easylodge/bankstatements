require 'spec_helper'

describe Bankstatements::Query do
  let(:subject) {Bankstatements::Query.new}

  it { should respond_to(:ref_id) }
  it { should respond_to(:access) }
  it { should respond_to(:accounts) }
  it { should respond_to(:institutions) } #attr
  it { should respond_to(:created_at) }
  it { should respond_to(:updated_at) }

  before(:each) do
    config = YAML.load_file('dev_config.yml')
    access_hash =
      {
        :url => config["url"],
        :api_key => config["api_key"],
        :username => config["username"],
        :password => config["password"],
        :institution => config["institution"]
      }

    subject.access = access_hash
  end

  describe ".login" do
    context "with invalid credentials" do
      required = [:username, :password, :url, :api_key]

      required.each do |attr|
        it "returns false unless #{attr} is set" do
          subject.access[attr] = nil
          expect(subject.login(Faker::Lorem.word)).to eq(false)
        end

        it "sets an error message" do
          subject.access[attr] = nil
          subject.login(Faker::Lorem.word)
          expect(subject.error).to match(/#{attr}/)
        end
      end
    end

    context "with no bank_slug" do
      it "returns false" do
        expect(subject.login(nil)).to eq(false)
      end

      it "sets an error message" do
        subject.login(nil)
        expect(subject.error).to match(/bank slug/)
      end
    end

    context "with valid credentials" do
      before(:each) do
        @response = {
          accounts: [
            {id: 0},
            {id: 1}
            ],
          user_token: Faker::Lorem.word
        }
        allow(subject).to receive(:post).and_return(@response)
      end

      it "does an http post" do
        expect(subject).to receive(:post).and_return(@response)
        subject.login(Faker::Lorem.word)
      end

      it "sets the access user_token" do
        subject.login(Faker::Lorem.word)
        expect(subject.access[:user_token]).to be_present
      end

      it "stores accounts per bank" do
        bank_slug = Faker::Lorem.word
        subject.login(bank_slug)

        expect(subject.accounts[bank_slug][:accounts].count).to eq(@response[:accounts].count)
      end

      it "returns true if a user token was set" do
        expect(subject.login(Faker::Lorem.word)).to eq(true)
      end

      context "real connection", :focus do
        before(:each) do
          allow(subject).to receive(:post).and_call_original
        end

        it "works" do
          subject.login(subject.access[:institution])


        end
      end
    end

  end


  describe ".get_institutions" do
    it "raises an exception if no access[:url] is present" do
      subject.access[:url] = nil
      expect{subject.get_institutions}.to raise_error("No API URL configured")
    end

    it "return any existing value" do
      subject.institutions = "preset"
      expect(subject.get_institutions).to eq("preset")
    end

    it "does not get new results if there is an existing value" do
      subject.institutions = "preset"
      expect(HTTParty).not_to receive(:get)
      subject.get_institutions
    end

    it "populates institution detail", :focus do
      subject.get_institutions
      expect(subject.institutions).to be_a(Array)
    end
  end

#   describe ".get_accounts" do
#     before(:each) do
#       subject.access[:username] = 12345678
#       subject.access[:password] = 'TestMyMoney'

#       subject.institutions = [
#         { slug: 'bank_a'},
#         { slug: 'bank_b'}
#       ]
#     end

#     it "raises an exception if no access[:url] is present" do
#       subject.access[:url] = nil
#       expect{subject.get_accounts}.to raise_error("No API URL configured")
#     end

#     it "raises an exception if no access[:username] is present" do
#       subject.access[:username] = nil
#       expect{subject.get_accounts}.to raise_error("No username available")
#     end

#     it "raises an exception if no access[:password] is present" do
#       subject.access[:password] = nil
#       expect{subject.get_accounts}.to raise_error("No password available")
#     end

#     it "fetches the accounts for all known institutions" do
#       allow(subject).to receive(:get_institutions).and_return([])
#       expect(subject).to receive(:get_institutions)
#       subject.get_accounts
#     end

#     it "performs a login for every institution" do
#       allow(subject).to receive(:login).and_return({})
#       expect(subject.institutions.count).to eq(2)
#       expect(subject).to receive(:login).exactly(subject.get_institutions.count).times
#       subject.get_accounts
#     end

#     it "assigns the account information to the bank key" do
#       allow(subject).to receive(:login).and_return({accounts: [{acc1: "foo"}]}, {accounts: [{acc2: "bar"}]})
#       subject.get_accounts
#       expect(subject.accounts.keys).to eq(subject.institutions.collect{|x| x[:slug]})
#       expect(subject.accounts["bank_a"]).to be_a(Array)
#       expect(subject.accounts["bank_b"]).to be_a(Array)
#       expect(subject.accounts["bank_a"]).to eq([{acc1: "foo"}])
#       expect(subject.accounts["bank_b"]).to eq([{acc2: "bar"}])
#     end

#     it "gets account information per institution", :focus do
#       subject.institutions = nil
#       subject.get_institutions
#       subject.institutions = subject.institutions.sample(3) #we dont want all of the banks
#       subject.get_accounts
# p subject.accounts
#       expect(subject.accounts.keys).to eq("foo")

#     end
#   end

  # describe ".post" do
  #   before(:each) do
  #     # prevent calling the actual URL, we jsut harvest the opts we pass in so we can invetigate them if we want
  #     allow(HTTParty).to receive(:post).with(any_args){|u, h|
  #       os = OpenStruct.new()
  #       os.headers = h[:headers]
  #       os.body = h[:body]
  #       os
  #     }
  #   end

  #   context "when invalid" do
  #     it "raises exception if there is no query json" do
  #       @query.enquiry = nil
  #       expect{@query.post}.to raise_error("No query json")
  #     end

  #     it "raises exception if there is no api_key" do
  #       @query.access[:api_key] = nil
  #       expect{@query.post}.to raise_error("No API KEY provided")
  #     end

  #     it "raises exception if there is no api url" do
  #       @query.access[:url] = nil
  #       expect{@query.post}.to raise_error("No API URL provided")
  #     end
  #   end

  #   context "when valid" do
  #     context "with headers" do
  #       before(:each) do
  #         # The structure here is dependent on our mock for the HTTParty message way at the top
  #         @headers = @query.post.headers
  #       end

  #       it "sets X-API-KEY" do
  #         expect(@headers['X-API-KEY'].present?).to eq(true)
  #       end

  #       it "sets X-OUTPUT-VERSION"  do
  #         expect(@headers['X-OUTPUT-VERSION']).to eq('20170401')  #to 20170401
  #       end

  #       it "sets Content-Type"  do
  #         expect(@headers['Content-Type']).to eq('application/json')  #to application/json
  #       end
  #       it "sets Accept" do
  #         expect(@headers['Accept']).to eq('application/json')   #to application/json
  #       end
  #     end

  #     it "posts the query" do
  #       expect(HTTParty).to receive(:post)
  #       @query.post
  #     end

  #     it "returns the response if it's available" do
  #       @query.response = Bankstatements::Response.new()
  #       expect(HTTParty).to_not receive(:post)
  #       expect(@query.post).to eq(@query.response)
  #     end

  #     it "return a Bankstatements::Response" do
  #       expect(@query.post).to be_a(Bankstatements::Response)
  #     end
  #   end
  # end
end
