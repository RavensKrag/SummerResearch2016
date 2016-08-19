# SummerResearch2016
GMU Catalog scraping, and course dependency graph


Tested with the following environment:


Ubuntu 16.04

ruby 2.3.0p0
rubygems 2.5.1
rake 10.4.2

Mongo 2.6.10





# Catalog Scraper

First, read the documentation for details and potential complications with trying to generate this dataset. (There should be a copy of the data avaiable for download next to the documentation, if you would rather not wait multiple hours do scrape the data yourself.)


make sure you have ruby installed, with gems
install bundler and rake
$ gem install bundler

(some systems provide rake with the ruby package, but rake is also available as a gem)

navigate to the 'catalog_scraper' directory and install dependencies:
$ bundle install

to actually run the scraper,
first navigate to the 'catalog_scraper/bin' directory
then:
$ rake

(This will not do anything, but it will tell you how to start up the Mongo server.)
(Make sure the directory specified by the --dbpath flag exists prior to starting Mongo.)

(This will actually fetch the data)
$ rake fetch_all:populate_index
(Wait about 30 minutes. See catalog_scraper/bin/rakefile for benchmark in comments)
$ rake fetch_all:populate_mongo_db
(Wait least 3 hours. See code comments for benchmark.)



# Course Dependency Graph - Web App

Need to install additional dependenices for the Web App.

Navigate to the 'web_app' directory this time, and install dependencies with bundler:
$ bundle install
(same command as above)


Now the dependencies for the Web App should be installed.


To run the app, as with running the scraper, make sure that Mongo is running.
Then, navigate to the 'web_app' directory and:
$ rake

The graph can now be viewed in any browser at the following address:
	http://localhost:4567/graphs/CS_BS_all/graph

NOTE: Arrows on edges do not render properly in Firefox. If you want to see arrows, try Chrome instead. (However, testing was done mostly in Firefox.)



