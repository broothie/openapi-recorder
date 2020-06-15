require 'active_support/json'
require_relative 'fake'

module Dsl
  class Path
    delegate :response, :fake, to: :@file

    def initialize(file)
      @file = file

      @data = {
        path_params: {},
        description: nil,
        query: {},
        headers: {},
        body: nil
      }
    end

    def description(description)
      @data[:description] = description
    end

    def path_params(path_params)
      @data[:path_params].merge!(path_params)
    end

    def query(query)
      @data[:query].merge!(query)
    end

    def headers(headers)
      @data[:headers].merge!(headers)
    end

    def json(object)
      headers 'Content-Type' => 'application/json'
      body object.to_json
    end

    def body(body)
      @data[:body] = body
    end
  end
end
