require 'active_support/core_ext'

class Recorder
  attr_reader :driver

  def initialize(driver, request)
    @driver = driver
    @req = request
  end

  def path_entry
    operation = {}

    operation[:description] = description if description.present?
    operation[:parameters] = parameters if parameters.present?

    if request.body.present?
      if %r{application/json} =~ request.headers['Content-Type']
        operation[:requestBody] = { content: { 'application/json' => { example: JSON.parse(request.body) } } }
      end
    end

    response_entry = {}
    response_entry[:description] = description if description.present?
    if response.body.present?
      content_type = response['Content-Type']
      response_entry[:content] = case content_type
      when %r{application/json}
        body = JSON.parse(response.body)
        { 'application/json' => { example: body, schema: schema_from_example(body) } }
      when %r{application/xml}
        body = Nokogiri::XML(response.body).to_h
        { 'application/xml' => { example: body, schema: schema_from_example(body) } }
      when %r{text/plain}
        { 'text/plain' => { example: response.body } }
      else
          { content_type.split(';').first => { example: response.body } }
      end
    end

    response_entry = nil if response_entry.empty?
    operation[:responses] = { response.status => response_entry }
    { request.path => { request.verb => operation } }
  end

  def description
    @req[:description]
  end

  def path_params
    @path_params ||= @req[:path_params].with_indifferent_access
  end

  def request
    @request ||= OpenStruct.new(
      verb: @req[:method].to_s,
      path: @req[:path],
      query: @req[:query],
      headers: @req[:headers],
      body: @req[:body]
    )
  end

  def replaced_path
    @replaced_path ||= request.path.split('/').map do |segment|
      match = segment.match(/{(\w+)}/)
      next segment unless match

      path_params[match.captures.first]
    end.join('/')
  end

  def parameters
    @parameters ||= begin
      parameters = request.path
        .split('/')
        .select { |segment| segment.match(/{\w+}/) }
        .map { |segment| segment.match(/{(\w+)}/).captures.first }
        .map { |name| { name: name, in: 'path', required: true, schema: { type: 'string' } } }

      parameters += request.query.map { |key, value| { name: key.to_s, in: 'query', example: value }}
      parameters += request.headers.map { |key, value| { name: key.to_s, in: 'header', example: value }}

      parameters
    end
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

  def client
    @client ||= driver.client
  end

  def response
    @response ||= client.send(request.verb) do |http|
      http.url replaced_path
      request.query.each { |key, value| http.params[key] = value }
      request.headers.each { |key, value| http.headers[key] = value }
      http.body = request.body if request.body
    end
  end
end
