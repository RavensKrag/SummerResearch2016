require 'rubygems'

# catalog_scraper_rakefile_path =
# 	File.expand_path(
# 		File.join(
# 			'..', '..', '..', 'catalog_scraper', 'bin', 'rakefile'
# 		),
# 		File.dirname(__FILE__)
# 	)
# p catalog_scraper_rakefile_path

# load catalog_scraper_rakefile_path

# load rakefile in order to load all of the dependencies 
# (there are some dependencies that are not gems)

# TODO: isolate dependency loading for 'catalog_scraper' gem into another file, so it can be easily loaded here.
# (or have a full-on gem-style setup, so I can require the library in a reasonable way.)

# ==================

# NOTE: can't actually load the rakefile here, because loading 'rake' inhibits Sinatra from starting



require 'bundler'
Bundler.require(:default)
require 'bundler/setup'

# other libs for 'catalog_scraper'
require 'yaml'
require 'csv'
require 'set'
require 'open-uri'

# other libs for this main thing
require 'json'



# NOTE: 'catalog_scraper' files us the 'PATH_TO_ROOT' constant, which is pretty bad, because I'm just polluting the global namespace with that constant. Need to move that into a module or something.

# Must expand '..' shortcut into a proper path. But that results in a shorter string.
PATH_TO_ROOT = File.expand_path '../..', '../../catalog_scraper/bin/rakefile'


# files
Dir.chdir PATH_TO_ROOT do
	require_all './lib/SummerResearch'
end


set :public_folder, File.join(File.dirname(__FILE__), '..', 'static')



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





# TODO: figure out a better way to declare these variables.
# don't want to have to duplicate this logic from the rakefile
# need to store these constants in a file that's easily loadable from here,
# and the 'catalog_scraper' rakefile.

filepath = File.expand_path('bin/data/required_courses.yaml', PATH_TO_ROOT)
required_courses ||= YAML.load_file(filepath)

SQLITE_DATABASE_FILEPATH = File.expand_path('bin/example.db', PATH_TO_ROOT)
catalog = SummerResearch::Catalog.new(SQLITE_DATABASE_FILEPATH)

# NOTE: can't use instance variables because of weird DSL scoping side-effects

get '/api/foo.json' do
	data = catalog.course_info('CS 101')
	
	
	JSON.generate data.to_h
end

get '/api/foo2.json' do
	
	data = [
		[150, 300],
		[300, 300],
		[450, 300]
	].collect{ |pair|
		{ 'x' => pair[0], 'y' => pair[1] }
	}
	
	
	JSON.generate data
end


# code copied over from the rakefile for 'catalog_scraper'
# not final implementation, just a sketch of getting program overview
get '/api/required_courses/ComputerScienceBS' do
	puts "=== setup data"
	# search for relevant programs of study
	
	list_of_degrees = [
		"Computer Science",
		"Information Technology",
		"Electrical Engineering",
		"Biology",
		"Psychology"
	]
	
	degrees = SummerResearch.search_programs_of_study(list_of_degrees)
	
	
	count = degrees.keys.size
	puts "#{count} programs found for search query."
	
	
	programs_of_study = degrees
	
	# TODO: output data on different degrees to different folders.
	
	program_name = "Computer Science, BS"
	url = programs_of_study[program_name]
	
	
	fragment = SummerResearch.requirements_subtree(url)
	
	course_list = SummerResearch.get_all_weird_link_urls(fragment)
	
	p course_list.first.class
	data = 
		course_list.collect do |catalog_link| 
			# catalog_link.to_h
			{  "id" => catalog_link.id  }
		end
	
	JSON.generate data
end




data =
	{"CS 101"=>["CS 112"], "CS 105"=>[], "CS 112"=>["MATH 104", "MATH 105", "MATH 113"], "CS 211"=>["CS 112"], "CS 262"=>["CS 211", "CS 222"], "CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"], "CS 310"=>["CS 211", "MATH 113", "CS 105"], "CS 321"=>["CS 310", "ENGH 302", "CS 421", "SWE 421", "CS 321"], "CS 330"=>["CS 211", "MATH 125"], "CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"], "CS 465"=>["CS 367"], "CS 483"=>["CS 310", "CS 330", "MATH 125"], "ECE 301"=>["MATH 125", "MATH 112"]}

get '/api/program_of_study/CS_BS' do
	nodes =
		data.collect{  |k,v|   [k, v] }.flatten.uniq
		.collect do |data|
			{
				'id' => data,
				'r' => data.split(' ')[1][0].to_i # first digit
			}
		end
	
	links =
		data.collect do |course, deps|
			deps.collect do |dependency|
				[course, dependency]
			end
		end
	links =
		links.flatten(1).collect do |course, dependency|
			{
				'source' => dependency,
				'target' => course,
				'color'  => '#3399FF'
			}
		end
	
	
	
	out = {
		'nodes' => nodes,
		'links' => links
	}
	
	JSON.generate out
end

get '/api/program_of_study/CS_BS/all' do
	out = data.collect{|k,v| [k,v ]}.flatten
	
	JSON.generate out
end

get '/api/program_of_study/CS_BS/paired_links' do
	out =
		data.collect do |parent, children|
			children.collect do |child|
				[parent, child]
			end
		end
	out.flatten!(1)
	
	JSON.generate out
end




# bin/database.log
# what the heck is this file? what is it a log of? SQLite? Mongo?
# man, this configuration is messed up...
