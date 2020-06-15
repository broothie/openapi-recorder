require 'delegate'
require 'json'
require 'nokogiri'
require 'active_support/core_ext'

class Response < SimpleDelegator
  def code
    status
  end

  def json
    @json ||= JSON.parse(body)
  end

  def xml
    @xml ||= Nokogiri::XML(body)
  end
end
