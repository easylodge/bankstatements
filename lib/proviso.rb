require 'active_record'
require 'proviso/version'
require 'proviso/query'
require 'httparty'
require 'proviso/railtie' if defined?(Rails)
require 'proviso/configuration'

module Proviso
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
