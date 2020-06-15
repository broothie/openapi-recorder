title 'Open API Spec'
description 'DSL for generating Open API Spec files against a working API'
version '0.0.0'

server description: 'httpbin.org', url: 'https://httpbin.org'

get '/get' do
  description 'get some data (this endpoint returns the query params)'
  query username: fake.username
end

puts response.body

get '/json' do
  description 'get some json data'
end

puts response.json

get '/xml' do
  description 'get some xml data'
end

puts response.xml
