PATH_TO_ROOT = File.expand_path '../..', __FILE__

# gems (for everything else)
require 'bundler/setup'

require 'require_all'
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'csv'

# files
Dir.chdir PATH_TO_ROOT do
	require_all './lib/SummerResearch'
end

require './main'




require "test/unit"

class TestDegreeSearch < Test::Unit::TestCase
	def test_foo
		
	end
end
