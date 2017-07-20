ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:',
  )
require_relative 'spec/schema'


@config = YAML.load_file('dev_config.yml')
@access_hash = {
  :url => @config["url"],
  :access_code => @config["access_code"],
  :password => @config["password"],
  :username => @config["username"],

}

@enquiry = {
  'foo' => 'bar'
}

@req = Bankstatement::query.new(access: @access_hash)

puts "You now have a request instance to use."
# @req.get_institutions
# @req.get_accounts

