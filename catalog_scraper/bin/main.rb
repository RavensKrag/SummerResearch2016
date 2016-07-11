#!/usr/bin/env ruby
# encoding: utf-8

module SummerResearch

DATA_DIR = File.join(PATH_TO_ROOT, 'bin', 'data')


class Main
	def initialize
		@degrees = Hash.new
		@courses = Hash.new
	end
	
	attr_reader :degrees
	
	
	# v actually used methods
	
	
	
	
	
	# Roughly imported from python sketch on how to meaningfully extract degree requirements
	# was only ever called from one pathway in rakefile. that pathway has been removed.
	# dependencies: foo1
	def foo6
		url = @degrees["Computer Science, BS"]
		# url = @degrees["Applied Computer Science, BS"]
		# url = @degrees["Biology, BA"]
		# url = @degrees["Biology, BS"]
		# url = @degrees["Psychology, BA"]
		
		
		# find a bunch of tags to collect,
		# and then print those tags to file, preserving the order from the document
		fragment = SummerResearch.requirements_subtree(url)
		puts fragment.length
		
		# all p and various levels of headers (h1, h2, ..., h12)
		fragment.css('p') + fragment.css( (1..12).collect{|i| "h#{i}" }.join(', ') )
		
		
		# collection = set({})
		# for tag in itertools.chain.from_iterable(x):
		# 	collection.add(tag)
		
		
		# x = [ [child for child in head.descendants if child in collection] for head in fragment]
		
		# puts x
		
		# Utilities.write_to_file("./human.html", x)
		
		
		# sometimes you see a <strong> sometimes you see a <strong><u> which is really bad...
	end
	
	
	
	
	
	
	
	
	
	
	
	
	
	# dependencies: foo1
	# precursors: foo6, SummerResearch.required_courses, SummerResearch.degree_requirements, foo2
	def foo7(program_name)
		url = @degrees[program_name]
		
		# util.degree_requirements(url)
		
		# TODO: consider moving this code back under util.degree_requirements if it does not use any of shared state, but keep it here for now for ease of writing
		
		
		fragment = SummerResearch.requirements_subtree(url)
		
		# TODO: need to improve this selector. catching some false positives.
		# wait, variable 'fragment' is a list...
		course_list = SummerResearch.get_all_weird_link_urls(fragment)
		
		
		
		# TODO: remove dupicate entries in the list of courses
			# not just as simple as removing duplicates from list
			# need to remove when two tuples have the same first element
			# also - want to keep original ordering
		# NOTE: this may not be necessary if the selection filter on links is improved
		
		
		Utilities.write_csv("./required_courses.csv", course_list)
		
		
		
		return course_list
		# get_info("CHEM 313")
		# return [course_list[0]]
		
		
	end
	
	# Backend dependency graph construction.
	# given a list of courses, figure out all of the dependencies
	def foo8(list_of_courses)
		list_of_courses.each do |course|
			# p course
			# puts course.id
		end
		
		# course_list = util.read_csv("./tmp/required_courses.csv")
		
		
		# out = dict()
		
		# for course in list_of_courses:
		# 	name, desc, url_fragment = course
			
		# 	dependencies = []
		# 	print self.get_dependencies(course)
		# 	out[name] = dependencies
		
		# return out
	end
	
	# query
	def foo9(class_dependencies, target_course)
		
	end
	
	# visualization
	def foo10(class_dependencies, output_filepath)
		
	end
	
	# Test the CatalogLink struct
	# 	basically, foo3 == foo12 + foo13
	# 	but foo12 and foo13 use actually use the Struct
	# (splitting it this way makes it easy to switch from test data to real data)
	def foo12()
		# NOTE: easily get data for this table from the intermediate file required_courses.csv
		sample = [
			[
				"CS 101",
				"Preview of Computer Science",
				"http://catalog.gmu.edu/preview_course.php?catoid=29&coid=302776&print"
			],
			[
				"CS 465",
				"Computer Systems Architecture",
				"http://catalog.gmu.edu/preview_course.php?catoid=29&coid=302800&print"
			],
			[
				"CS 475",
				"Concurrent and Distributed Systems",
				"http://catalog.gmu.edu/preview_course.php?catoid=29&coid=302803&print"
			],
			[
				"EVPP 110",
				"The Ecosphere: An Introduction to Environmental Science I",
				"http://catalog.gmu.edu/preview_course.php?catoid=29&coid=303982&print"
			],
			[
				"Mason Core UGU",
				"Global Understanding",
				"http://catalog.gmu.edu/preview_course.php?catoid=29&coid=308635"
			]
		].collect{|a,b,c| SummerResearch::CatalogLink.new(a, b, c, 'manual') }
		return sample
	end
	
	
	
	
	
	class << self
	
	def foo13(course_list)
		output_data = 
			course_list.collect do |course|
				puts course.id
				SummerResearch::CourseInfo.new(course).fetch
			end
		# p output_data
		Utilities.write_to_file('./course_info.yaml', output_data.to_yaml)
		
		return output_data
	end
	
	
	# find courses that fail parsing
	# want to see some examples of the unexpected
	# 
	# prints dots to let you know something is happening
	# only prints out courses that are "weird"
	# 
	# Does basicaly the same thing as foo13, but includes extra code to help report errors.
	def foo11(course_list)
		flag = true
		
		course_list.each do |course|
			begin
				SummerResearch::CourseInfo.new(course).fetch
			rescue StandardError => e
				if flag
					puts ""
					flag = false
				end
				
				puts course.id
				puts course.description
				puts course.url
				puts "Catalog Link format: #{course.link_type}"
				# throw e
				
				# output the data from the exception
				# (the program will still continue to run)
				# (resulting in all errors printed in one place)
				puts e.message
				e.backtrace.each do |line|
					puts "\t" + line
					# indent the lines of the backtrace.
					# makes it easier to see things when you start getting multiple errors
				end
				puts "=============="
				puts
				puts
			else
				flag = true
				print "."
			end
		end
		
		puts ""
	end
	
	# Like foo11, but with even more debug information. 
	# 
	# most of the code in this method comes directly from foo11 above
	# only the method call on CouseInfo has been changed from #fetch to #test_types
	def foo14(course_list)
		flag = true
		
		course_list.each do |course|
			begin
				SummerResearch::CourseInfo.new(course).test_types
			rescue StandardError => e
				if flag
					puts ""
					flag = false
				end
				
				puts course.id
				puts course.description
				puts course.url
				puts "Catalog Link format: #{course.link_type}"
			else
				flag = true
			ensure
				puts "=============="
				puts
				puts
			end
		end
		
		puts ""
	end
	
	end
end


end
