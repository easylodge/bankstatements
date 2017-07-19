class Bankstatements::Request < ActiveRecord::Base
  self.table_name = "bankstatement_requests"

  serialize :access
  serialize :accounts

  attr_accessor :institutions

  def get_institutions
    raise "No API URL configured" unless access[:url]
    self.institutions ||= get(access[:url] + "institutions")['institutions']
  end

  def get_accounts
    raise "No API URL configured" unless access[:url]
    raise "No username available" unless access[:username]
    raise "No password available" unless access[:password]

    self.accounts ||= {}
    get_institutions.each do |bank|
      self.accounts[bank[:slug]] ||= login(bank[:slug])[:accounts]
    end
    # NOTE: login returns account listing information
    # self.accounts ||= get(access[:url] + 'accounts')
    self.accounts
  end

  def get_statements(account_number)
    # We need to have accounts loaded before we can try and do statements
    raise "No accounts loaded" unless self.accounts.present?

    # we need to only pull the statement for the specified account number
    # so first we need to find the bank
    bank = find_bank_for(account_number)
    account = find_account_for(account_number)

    request = {
      accounts: {
        "#{bank[:slug]}": [account[:id]]
      }
    }
    response = post(access[:url] + "statements", request)
    # delete any existing copy of the account, we now have better info
    self.accounts.map!{|acc|
      if acc[:accountNumber] == account_number
        response[bank[:slug]][:accounts][0]
      else
        acc
      end
    }
  end

  # gets all the files for previous queries
  def get_files
    post(access[:url] + "statements", request)
  end

  private

  def headers
    request_headers = {
      'X-API-KEY' => access[:api_key],
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'X-OUTPUT-VERSION' => '20170401'
    }
    request_headers.merge!({'X-USER-TOKEN': access[:user_token]}) if access[:user_token].present?

    request_headers
  end

  def get(url)
    http_response = HTTParty.get(url, headers: headers)
    http_response.parsed_response.with_indifferent_access
  rescue
    {error: "Failure to connect to #{url}"}
  end

  def post(url, payload)
    http_response = HTTParty.get(url, headers: headers, body: payload)
    http_response.parsed_response.with_indifferent_access
  rescue
    {error: "Failure to connect to #{url}"}
  end

  def login(bank_slug)
    credentials = {
      "credentials": {
        "institution": bank_slug,
        "username": access[:username],
        "password": access[:password]
      },
      "referral_code": ref_id || ''
    }
    p credentials
    p access[:url] + "login"
    x = post(access[:url] + "login", credentials)
    p x
    x
  end

  def find_bank_for(account_number)
    result = nil
    result = self.accounts.detect do |bank|
      bank[:accounts].detect do |acct|
        acct[:accountNumber] == account_number
      end
    end
    Hash[*result]
  end

  def find_account_for(account_number)
    result = nil
    self.accounts.detect do |bank|
      result = bank[:accounts].detect do |acct|
        acct[:accountNumber] == account_number
      end
    end
    Hash[*result]
  end
end
