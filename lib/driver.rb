require 'faraday'
require 'yaml'
require 'active_support/core_ext'
require_relative 'recorder'
require_relative 'dsl/file'

class Driver
  attr_reader :filename
  attr_reader :options
  attr_reader :data

  def self.run!(filename)
    new(filename).run!
  end

  def initialize(filename)
    @filename = filename

    @options = {
      output: 'openapi.yml'
    }

    @data = {
      openapi: '3.0.3',
      info: {},
      servers: [],
      paths: {}
    }
  end

  def run!
    Dsl::File.new(self).instance_eval(source, filename)

    yaml = data.deep_stringify_keys.to_yaml
    puts yaml
    File.write(options[:output], yaml)

    client.close
  end

  def request(request)
    recorder = Recorder.new(self, request)
    data[:paths].deep_merge!(recorder.path_entry)

    recorder.response
  end

  def source
    @source ||= File.read(filename)
  end

  def client
    @client ||= Faraday.new(url)
  end

  def url
    @url ||= data[:servers]&.first&.fetch(:url)
  end

  def schema_from_example(example)
    case example
    when Hash
      { type: 'object', properties: example.map { |key, value| [key, schema_from_example(value)] }.to_h }
    when Array
      { type: 'array', items: example.map(&method(:schema_from_example)) }
    else
      { type: example.class.name.downcase }
    end
  end
end
