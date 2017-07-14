ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:',
  )
require_relative 'spec/schema'


@config = YAML.load_file('dev_config.yml')
@access_hash = {
  :url => @config["url"],
  :access_code => @config["access_code"],
  :password => @config["password"]
}

@enquiry = {
  'foo' => 'bar'
}

@req = Bankstatement::Request.new(access: @access_hash, enquiry: @enquiry)
@post = @req.post
@res = Bankstatement::Response.create(json: @post.body, headers: @post.header, code: @post.code, success: @post.success?)

# puts "This is the result of Bankstatement::Request.access: #{Bankstatement::Request.access}"
puts "You have a @req and @res object to use"




