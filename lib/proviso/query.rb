class Proviso::Query < ActiveRecord::Base
  self.table_name = "proviso_queries"

  serialize :access
  serialize :accounts

  attr_accessor :institutions

  def login(bank_name)
    return false unless valid_credentials?

    bank_slug = bank_slug(bank_name)

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
    response = post(proviso_url + "login", credentials)
    # set the user token into the access hash for re-use
    self.access[:user_token] = response[:user_token]

    self.accounts ||= {}
    # set the bank slug on each account for convenience
    if response[:user_token].present?
      self.accounts[bank_slug] = {accounts: []}
      response[:accounts].each do |acc|
        # make sure we replace any existing account info for this bank
        self.accounts[bank_slug][:accounts] << acc.merge({bank_slug: bank_slug})
      end if response[:accounts].present?
    end

    response[:error].nil? && response[:user_token].present?
  end

  def bank_slug(bank_name)
    institutions.detect {|i| i[:name].downcase == bank_name.downcase }[:slug]
  rescue
    nil
  end

  def get_accounts(bank_slug)
    raise "No API URL configured" unless proviso_url.present?
    raise "No user token present" unless access[:user_token].present?
    raise "No bank slug provided" unless bank_slug.present?
    self.accounts[bank_slug] ||= get(proviso_url + "accounts")[:accounts][bank_slug]
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

    post(proviso_url + "statements", request)
  end

  # gets all the files for previous queries
  def get_files
    return @files if @files.present?
    raise "No user token present" unless access[:user_token].present?
    @files ||= get(proviso_url + "files")
    @files.presence || raise("No files available")
  end

  def institutions
    return @institutions if @institutions.present?
    raise "No API URL configured" unless proviso_url
    @institutions ||= get(proviso_url + "institutions")[:institutions]
    @institutions.presence || raise("Could not fetch institutions")
  end

  private

  def headers
    request_headers = {
      'X-API-KEY' => proviso_api_key,
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
    if !proviso_url.present?
      self.error = "No url set"
    elsif !proviso_api_key.present?
      self.error = "No api_key set"
    elsif !access[:username].present?
      self.error = "No username set"
    elsif !access[:password].present?
      self.error = "No password set"
    end
    self.error.blank?
  end

  def proviso_url
    access[:url] || Proviso.configuration.url
  end

  def proviso_api_key
    access[:api_key] || Proviso.configuration.api_key
  end
end
