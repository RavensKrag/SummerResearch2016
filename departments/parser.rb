#!/usr/bin/env ruby
# encoding: utf-8


# gems
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/testtask'

require 'bundler/setup'
require 'require_all'


# gems
require 'open-uri'
require 'nokogiri'
require 'yaml'
require 'csv'
require 'set'



def write_csv(filepath, data)
	CSV.open(filepath, 'w') do |csv|
		data.each do |x|
			csv << x
		end
	end
end




xml = Nokogiri::HTML(open('data/dept_codes.html'))

options = xml.css('select').children.select{  |x| x.is_a? Nokogiri::XML::Element }
out = 
	options.collect do |option_node|
		option_code = option_node["value"]
		text = option_node.inner_text.strip
		
		match_data = text.match(/(.*?) (\(.*\))/)
		
		
		if match_data
			[option_code, match_data[2].tr('()', '  ').strip, match_data[1]]
		else
			# "Mason Core"
			[option_code, text]
		end
	end

write_csv('data/dept_codes.csv', out)


