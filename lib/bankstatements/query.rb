class Bankstatements::Query < ActiveRecord::Base
  self.table_name = "bankstatement_queries"

  serialize :access
  serialize :accounts

  attr_accessor :institutions
  attr_accessor :files_available

  def login(bank_slug)
    return false unless valid_credentials?

    unless bank_slug.present?
      self.error = "No bank slug provided"
      return false
    end

    credentials = {
      'credentials' => {
        'institution' => bank_slug,
        'username' => access[:username],
        'password' => access[:password]
      },
      'referral_code' => ref_id || 'xxx'
    }
    self.access[:user_token] = nil #post will fail with a stale user token
    response = post(access[:url] + "login", credentials)
    # set the user token into the access hash for re-use
    self.access[:user_token] = response[:user_token]

    self.accounts ||= {}
    # set the bank slug on each account for convenience
    if response[:user_token].present?
      self.accounts[bank_slug] = {accounts: []}
      response[:accounts].each do |acc|
        # make sure we replace any existing account info for this bank
        self.accounts[bank_slug][:accounts] << acc.merge({bank_slug: bank_slug})
      end
    end

    self.files_available = false

    response[:user_token].present?
  end

  def get_institutions
    raise "No API URL configured" unless access[:url]
    self.institutions ||= get(access[:url] + "institutions")[:institutions]
  end

  def get_accounts(bank_slug)
    raise "No API URL configured" unless access[:url].present?
    raise "No user token present" unless access[:user_token].present?
    raise "No bank slug provided" unless bank_slug.present?
    self.accounts[bank_slug] ||= get(access[:url] + "accounts")[:accounts][bank_slug]
  end

  def get_statements(account_number)
    # We need to have accounts loaded before we can try and do statements
    raise "No accounts loaded" unless self.accounts.present?

    # we need to only pull the statement for the specified account number
    # so first we need to find the bank
    account = find_account_for(account_number)
    request = {
      accounts: {
        "#{account[:bank_slug]}": [account[:id]]
      }
    }
    response = post(access[:url] + "statements", request)

    self.files_available = true
    response
  end

  # gets all the files for previous queries
  def get_files
    return @files if @files.present?
    raise "No user token present" unless access[:user_token].present?
    raise "No files available" unless self.files_available?
    @files ||= get(access[:url] + "files")
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
    http = HTTParty.get(url, headers: headers)
    http.parsed_response.deep_symbolize_keys
  rescue
    {error: "Failure to connect to #{url}"}
  end

  def post(url, payload)
    http = HTTParty.post(url, {headers: headers, body: payload.to_json})
    http.parsed_response.deep_symbolize_keys
  rescue
    {error: "Failure to connect to #{url}"}
  end

  def find_account_for(account_number)
    result = nil
    self.accounts.detect do |bank, accounts|
      result = accounts.with_indifferent_access[:accounts].detect do |acc|
        acc[:accountNumber] == account_number
      end
    end
    result
  end

  def valid_credentials?
    self.error = nil
    if !access[:url].present?
      self.error = "No url set"
    elsif !access[:api_key].present?
      self.error = "No api_key set"
    elsif !access[:username].present?
      self.error = "No username set"
    elsif !access[:password].present?
      self.error = "No password set"
    end
    self.error.blank?
  end

end