module Proviso
  class Configuration
    attr_accessor :url, :api_key

    def initialize(args = {})
      @url = args[:url]
      @api_key = args[:api_key]
    end
  end
end