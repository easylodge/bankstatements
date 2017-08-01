require 'spec_helper'

describe Proviso::Query do
  let(:subject) {Proviso::Query.new}

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

  xdescribe ".login" do
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

      it "adds the bank_slug to each account" do
        bank_slug = Faker::Lorem.word
        expect(subject.login(bank_slug)).to eq(true)
        subject.login(bank_slug)
        expect(subject.accounts[bank_slug][:accounts].first).to eq(@response[:accounts].first.merge(bank_slug: bank_slug))
      end

      it "sets the :files_available flag to false" do
        subject.login(Faker::Lorem.word)
        subject.files_available = true
        expect(subject.files_available).to be_false
      end

      context "real connection" do
        before(:each) do
          allow(subject).to receive(:post).and_call_original
        end

        it "works" do
          subject.login(subject.access[:institution])
          subject.accounts.each_pair do |bank_slug, values|
            values[:accounts].each do |acc|
              expect(acc.keys.count).to be > 0
              expect(acc["available"].to_f).to be > 0
            end
          end
          p subject.accounts
        end
      end
    end
  end

  xdescribe ".get_institutions" do
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

    it "populates institution detail" do
      subject.get_institutions
      expect(subject.institutions).to be_a(Array)
    end
  end

  xdescribe ".get_accounts" do
    before(:each) do
      subject.institutions = [
        { slug: 'bank_a'},
        { slug: 'bank_b'}
      ]

      subject.access[:user_token] = Faker::Lorem.word
    end

    it "raises an exception if no access[:url] is present" do
      subject.access[:url] = nil
      expect{subject.get_accounts(subject.institutions.sample[:slug])}.to raise_error("No API URL configured")
    end

    it "raises an exception if no access[:user_token] is present" do
      subject.access[:user_token] = nil
      expect{subject.get_accounts(subject.institutions.sample[:slug])}.to raise_error("No user token present")
    end

    it "raises an exception if no bank_slug is present" do
      expect{subject.get_accounts(nil)}.to raise_error("No bank slug provided")
    end

    context "with exsiting accounts" do
      before(:each) do
        # prep some fake info
        subject.accounts = {
          Faker::Lorem.word => Faker::Lorem.sentence.split()
        }
      end

      it "gets account information per institution" do
        expect(subject.get_accounts(subject.accounts.keys.first)).to eq(subject.accounts.first.last)
      end

      it "does not call login" do
        allow(subject).to receive(:get).and_return({accounts: {}})
        expect(subject).not_to receive(:login).with(any_args)
        subject.get_accounts("dummy")
      end
    end

    context "without existing accounts" do
      before(:each) do
        subject.accounts = {}
      end

      it "fetches account information" do
        dummy = {
          accounts: {
            "dummy": []
          }
        }
        expect(subject).to receive(:get).with(subject.access[:url] + "accounts").and_return(dummy)
        subject.get_accounts("dummy")
      end
    end

    xcontext "real connection" do
      it "works" do
        subject.login(subject.access[:institution])
        subject.accounts.each_pair do |bank_slug, values|
          # clear the accounts to force a fetch
          subject.accounts[bank_slug] = nil
          subject.get_accounts(bank_slug)
          expect(subject.accounts[bank_slug]).not_to eq(nil)
        end
      end
    end
  end

  describe ".get_statements" do
    before(:each) do
      # This dummy reponse is from the API documentation
      @response =
        {
          "accounts": {
            "boq": {
              "accounts": [
                {
                  "name": "Day2Day Plus",
                  "accountNumber": "22035291",
                  "id": 0,
                  "bsb": "124-001",
                  "balance": "1.00",
                  "available": "1.00",
                  "accountHolder": "Mr A C Holder",
                  "accountType": "transaction",
                  "statementData": {
                    "details": [
                      {
                        "date": "09-06-2015",
                        "text": "TFR TO ACCOUNT 022114714 IB2-25238951",
                        "notes": nil,
                        "amount": 1.01,
                        "type": "Debit",
                        "balance": "1.00"
                      },
                      {
                        "date": "14-12-2014",
                        "text": "TFR FROM 022114714 IB2-06194359",
                        "notes": nil,
                        "amount": 1.01,
                        "type": "Credit",
                        "balance": "2.16"
                      }
                    ],
                    "totalCredits": "8.17",
                    "totalDebits": "8.32",
                    "openingBalance": "1.15",
                    "closingBalance": "1.00",
                    "startDate": "12-12-2014",
                    "endDate": "17-06-2015",
                    "minBalance": "0.00",
                    "maxBalance": "2.16",
                    "dayEndBalances": [
                      {
                        "date": "10-06-2015",
                        "balance": "1.00"
                      }
                    ],
                    "minDayEndBalance": nil,
                    "daysInNegative": 0,
                    "errorMessage": "",
                    "analysis": { }
                  },
                  "institution": "Bank of Queensland"
                }
              ]
            }
          },
          "user_token": "1ebf...8093"
        }

      allow(subject).to receive(:post).and_return(@response)

      # NOTE: this data is from a test call to 'login'
      subject.accounts = {"bank_of_statements"=>{:accounts=>[{"accountHolder"=>"Mary Jones", "name"=>"Transaction Account", "accountNumber"=>"456789", "id"=>0, "bsb"=>"123-456", "balance"=>"123.45", "available"=>"123.45", "accountType"=>"transaction", "bank_slug"=>"bank_of_statements"}, {"accountHolder"=>"Mary Jones and Tom Jones", "name"=>"Savings Account", "accountNumber"=>"945315", "id"=>1, "bsb"=>"123-456", "balance"=>"3123.45", "available"=>"3123.45", "accountType"=>"savings", "bank_slug"=>"bank_of_statements"}, {"accountHolder"=>"Mary Jones and Tom Jones", "name"=>"Credit Card", "accountNumber"=>"XXXX XXXX XXXX 7654", "id"=>2, "bsb"=>"", "balance"=>"-3193.45", "available"=>"15553.55", "accountType"=>"credit card", "bank_slug"=>"bank_of_statements"}]}}.deep_symbolize_keys
    end

    it "raises an exception if no accounts are present" do
      subject.accounts = nil
      expect{subject.get_statements(Faker::Lorem.word)}.to raise_error("No accounts loaded")
    end

    it "looks up an account based on the number" do
      account_number = subject.accounts[:bank_of_statements][:accounts][0][:accountNumber]
      expect(subject).to receive(:find_account_for).with(account_number).and_call_original
      subject.get_statements(account_number)
    end

    context "real connection", :focus do
      before(:each) do
        allow(subject).to receive(:post).and_call_original
      end

      it "works" do
        subject.login(subject.access[:institution])
        account_number = subject.accounts.with_indifferent_access[:bank_of_statements][:accounts][0][:accountNumber]
        expect(subject.get_statements(account_number)).to eq(55)
      end
    end
  end

  describe ".get_files" do
    before(:each) do
      # placeholder
    end

    it "raises an exception if no access[:user_token] is present" do
      subject.access[:user_token] = nil
      expect{subject.get_files()}.to raise_error("No user token present")
    end

    it "raises an exception if no :files_available is false" do
      subject.files_available = [nil, false].sample
      expect{subject.get_files()}.to raise_error("No files available")
    end

    it "does not call the API if there are files present" do
      expect(subject).to receive(:get).and_return("some files").exactly(1).times
      subject.get_files()
    end

    it "returns existing files if any" do
      expect(subject).to receive(:get).and_return("some files")
      expect(subject.get_files()).to eq("some files")
    end
  end

  # PRIVATE

  describe ".headers" do
    it "includes the api_key"
    it "includes the X-USER-TOKEN if available"
  end

  describe ".get" do
    it "calls HTTParty::get with the url provided"
    it "calls HTTParty::get with headers"
    it "returns a hash with symbolised keys"
  end

  describe ".post" do
    it "calls HTTParty::post with the url provided"
    it "calls HTTParty::post with headers"
    it "calls HTTParty::post with body set to the payload provided, converted to json"
    it "returns a hash with symbolised keys"
  end

  describe ".find_account_for" do
    it "detects a known account with matching number"
    it "returns an account hash"
  end

  describe ".valid credentials?" do
    it "checks for :url, :api_key, :username, :password in the access hash"
    it "returns true if no errors are logged"
  end
end
