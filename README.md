# Bankstatements

Ruby gem to make requests to Bankstatements.com.au service. Website: [https://www.bankstatements.com.au/](https://www.bankstatements.com.au/)

## Installation

Add this line to your application's Gemfile:

    gem 'bankstatements'

And then execute:

    $ bundle

Then run install generator:

	rails g bankstatements:install

Then run migrations:

    rake db:migrate


## Usage

### Request


    request = Bankstatement::Request.create(...)

Attributes for access_hash:

    {
        :url => config["url"],
        :api_key => config["api_key"]
    }


#### Instance Methods:

    request.access - Access Hash
    request.json - JSON body request

### Response
	post = request.post
    response = Bankstatement::Response.create(json: post.body, headers: post.headers, code: post.code, success: post.success?)

#### Instance Methods:

    response.as_hash - Hash of whole response
    response.json - JSON of response
    response.code - Response status code
    response.headers - Response headers
    response.success? - Returns true or false (based on Httparty response)
    response.error - Response errors if any


## Contributing

1. Fork it ( http://github.com/easylodge/bankstatements/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. See dev.rb file in root
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
