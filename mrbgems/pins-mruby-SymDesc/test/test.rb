if RUBY_ENGINE == "ruby"
require "simplecov"

SimpleCov.start
require "test/unit"
require_relative "../lib/SymDesc.rb", __FILE__

include SymDesc
end