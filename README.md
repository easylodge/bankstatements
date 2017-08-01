# Proviso

Ruby gem to make requests to Bankstatements.com.au service. Website: [https://www.bankstatements.com.au/](https://www.bankstatements.com.au/)

## Installation

Add this line to your application's Gemfile:

    gem 'proviso'

And then execute:

    $ bundle

Then run install generator:

	rails g proviso:install

Then run migrations:

    rake db:migrate


## Usage

### Request


    request = Proviso::Query.create(...)

Attributes for access_hash:

    {
        :url => config["url"],
        :api_key => config["api_key"]
    }


#### Instance Methods: (Needs to be updated)

    request.access - Access Hash
    request.json - JSON body request

## Contributing

1. Fork it ( http://github.com/easylodge/proviso/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. See dev.rb file in root
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request
