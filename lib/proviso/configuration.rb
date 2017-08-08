module Proviso
  class Configuration
    attr_accessor :url, :api_key

    def initialize
      @url = nil
      @api_key = nil
    end
  end
end