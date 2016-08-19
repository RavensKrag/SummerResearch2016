require 'rubygems'

require 'bundler'
Bundler.require(:default)
require 'bundler/setup'

require 'rgl/adjacency'
require 'rgl/traversal'
require 'rgl/bidirectional'


# other libs for 'catalog_scraper'
require 'yaml'
require 'csv'
require 'set'

# other libs for this main thing
require 'json'






Dir.chdir File.expand_path('../', File.dirname(__FILE__)) do
	# Files for the web app specifically
	require_all './models'
	require_all './lib'
	
	
	
	# files
	repo_root = ->(){
		path_to_file = File.expand_path(File.dirname(__FILE__))
		
		dir_list = path_to_file.split(File::SEPARATOR)
		i = dir_list.find_index("SummerResearch2016")
		
		return File.join(*dir_list[0..i])
	}[]
	
	require File.expand_path('./catalog_scraper/lib/SummerResearch/course_info', repo_root)
	
	
	
	configure do
		set :public_folder, File.expand_path('./static')
		
		set :views, [
			File.expand_path('./views')
		]
		
		set :logging, :true
		enable :logging
		# set :logger, Logger.new(STDOUT)
		# use Rack::CommonLogger, Logger.new(STDOUT)
	end
end







get '/' do
	
	# haml 'foo'
	# erb :index
	
	File.read(File.expand_path('index.html', settings.public_folder))
	# just vendor the static index.html page for now
	
end

# TODO: update ruby soon.  2.3.0 is apparently outdated now.




# ===== REST API =====


get '/api/test' do
	data = {'hello world!' => 42}
	
	
	JSON.generate(data)
end





@mongo_ip      = "127.0.0.1"
@mongo_port    = "12345"
@mongo_address = [@mongo_ip, @mongo_port].join(':')
mongo = Mongo::Client.new([ @mongo_address ], :database => 'mydb')



get '/api/foo.json' do
	
	data = [
		[150, 300],
		[300, 300],
		[450, 300]
	].collect{ |pair|
		{ 'x' => pair[0], 'y' => pair[1] }
	}
	
	
	JSON.generate data
end





# bin/database.log
# what the heck is this file? what is it a log of? SQLite? Mongo?
# man, this configuration is messed up...



get '/api/course_info/:course' do
	course_id = params['course']
	
	
	# NOTE: not sure why the Catalog object doesn't work (it apparently can't connect to the SQLite DB?) but it's probably better to just interface with Mongo directly anyway.
	
	
	course_id = course_id.tr('_', ' ')
	
	# course = catalog.course_info(course_id)
		catalog_year = "2016-2017"
		document = 
				mongo[:course_info].find(
					:course_id => course_id,
					:catalog_year => catalog_year
				)
				.limit(1)
				.first
		
		
		raise "Document not found. Was looking for a course called '#{course_id}' for the #{catalog_year} catalog_year" if document.nil? 
		
		course = SummerResearch::CourseInfo.load(document)
	
	
	return JSON.generate(course.to_h)
end







model = Models::ComputerScience_BS.new()

# SummerResearch::Utilities.write_to_file(
# 	'./CS_BS_courses.txt', model.all_courses.join("\n")
# )

get '/api/program_of_study/CS_BS' do
	model.json
end

get '/api/program_of_study/CS_BS/all' do
	model.json_list_all_courses
end



# Create a graph page based on an erb template
get '/graphs/:name/graph' do
	erb :index, :locals => {
		:foo => 'downward_edges.js',
		:d3_version => '3.5.17',
		
		:stylesheets => [
			'downward_edges_example.css',
			'style.css',
		],
		
		:test => 'hello world',
		
		:bar  => 'course_info_display.js'
	}
end

# return the data needed by the corresponding graph
get '/graphs/:name/dynamic_data.json' do
	static_json_files = [
		'chris'
	]
	
	
	if static_json_files.include? params['name']
		# --- serve static documents
		
		filepath = 
			File.expand_path(
				"../static/#{params['name']}.json",
				File.dirname(__FILE__)
			)
		
		data = File.read(filepath)
		
		return data
	else
		# --- serve dynamic data
		
		return model.json_directional(params['name'], logger)
		
		# # return empty JSON document for now
		# return '{"nodes":[], "edges":[], "constraints":[]}'
	end
end

