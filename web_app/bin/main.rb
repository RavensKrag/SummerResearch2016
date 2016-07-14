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



# NOTE: 'catalog_scraper' files us the 'PATH_TO_ROOT' constant, which is pretty bad, because I'm just polluting the global namespace with that constant. Need to move that into a module or something.

# Must expand '..' shortcut into a proper path. But that results in a shorter string.
PATH_TO_ROOT = File.expand_path '../..', '/home/ravenskrag/Work/Rangwalla Summer NSF/Work/SummerResearch2016/catalog_scraper/bin/rakefile'


# files
Dir.chdir PATH_TO_ROOT do
	require_all './lib/SummerResearch'
end


set :public_folder, File.join(File.dirname(__FILE__), '..', 'static')


get '/' do
	
	# haml 'foo'
	# "hello world!"
	# erb :index
	
	File.read(File.expand_path('index.html', settings.public_folder))
	
end
