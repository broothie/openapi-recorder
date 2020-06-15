require 'faker'

module Dsl
  module Fake
    def fake
      Faker::Internet
    end
  end
end
