require_relative 'path'
require_relative 'fake'
require_relative '../response'

module Dsl
  class File
    include Fake
    attr_reader :response

    def initialize(driver)
      @driver = driver
    end

    def options(options)
      @driver.options.merge!(options)
    end

    %i[title description version].each do |info|
      define_method(info) do |string|
        @driver.data[:info][info] = string
      end
    end

    def server(description:, url:)
      @driver.data[:servers] << { description: description, url: url }
    end

    %i[get post put patch delete].each do |method|
      define_method(method) do |path, &block|
        request = { method: method, path: path }

        context = Path.new(self)
        context.instance_exec(&block) unless block.nil?
        request.merge!(context.instance_variable_get(:@data))

        @response = Response.new(@driver.request(request))
      end
    end
  end
end
