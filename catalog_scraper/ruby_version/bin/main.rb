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
	
	
	
	# dependencies: none
	# get possible degree program requrement lists
	def foo1(list_of_degrees)
		url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
		@degrees = SummerResearch.search_programs_of_study(url, list_of_degrees)
		
		count = @degrees.keys.size
		puts "#{count} programs found for search query."
		
		filepath = File.expand_path("./programs_of_study.yaml", DATA_DIR)
		puts "Writing to file '#{filepath}'"
		
		File.open(filepath, 'w') do |f|
			f.puts @degrees.to_yaml
		end
	end
		
	# dependencies: foo1
	# get the list of courses for one program, based on its name
	def foo2(degree_name)
		url = @degrees[degree_name]
		# url = self.degree_dict["Applied Computer Science, BS"]
		# url = self.degree_dict["Biology, BA"]
		# url = self.degree_dict["Biology, BS"]
		# url = self.degree_dict["Psychology, BA"]
		
		course_list = SummerResearch.degree_requirements(url)
		# puts course_list.to_yaml
		
		# TODO: remove dupicate entries in the list of courses
			# not just as simple as removing duplicates from list
			# need to remove when two tuples have the same first element
			# also - want to keep original ordering
		# NOTE: this may not be necessary if the selection filter on links is improved
		
		
		Utilities.write_csv('./required_courses.csv', course_list)
		
		# arr_of_arrs = CSV.parse("CSV,data,String")
		
		return course_list
	end
	
	# Test SummerResearch.course_info on various URLs with different sorts of attributes
	# NOTE: not all courses specify all attributes. 
	#   ex) If there are no corequisites, the field is omitted
	def foo3
		[
			["CS 330",   "http://catalog.gmu.edu/preview_course.php?catoid=29&coid=302788&print"],
			["STAT 344", "http://catalog.gmu.edu/preview_course.php?catoid=29&coid=306778&print"],
			["PSYC 320", "http://catalog.gmu.edu/preview_course.php?catoid=29&coid=306130&print"]
		].each do |name, url|
			puts name
			info = SummerResearch.course_info(url)
			print info.to_yaml
			puts "========="
		end
	end
	
	# dependencies: none
	def foo5(list_of_deparments)
		@courses = Hash.new
		
		list_of_deparments.each do |dept|
			@courses[dept] = SummerResearch.search_by_department(dept)
		end
	end
	
	# dependencies: foo5
	# check the cache for info on a particular course
	def foo4
		# p @courses["CS"]
		Utilities.write_to_file('./courses.yaml', @courses.to_yaml)
		
		course_id = "CS 101"
		# TODO: figure out what the anatomy of a course is
		# * CS 101
		# * Preview of Computer Science
		# * Description
		# * Section ID?
		# --- these are all different things
		
		dept, number = course_id.split
		course = @courses[dept].find{  |x| x.id.include? number }
		
		return SummerResearch.course_info(course.url)
	end
	
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
			puts course.id
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
			]
		].collect{|a,b,c| SummerResearch::CatalogLink.new(a, b, c) }
		return sample
	end
	
	def foo13(course_list)
		# WARNING: EVPP 110 fails with #course_info because it is not as flat as expected.
		
		output_data = 
			course_list.collect do |course|
				puts course.id
				SummerResearch.course_info(course.url)
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
				SummerResearch.course_info(course.url)
			rescue StandardError => e
				if flag
					puts ""
					flag = false
				end
				
				puts course.id
				puts course.description
				puts course.url
				# throw e
			else
				flag = true
				print "."
			end
		end
		
		puts ""
	end
	
	
	private
	
	def helper
		
	end
	
	# dependencies: foo5
	# precursor: foo4
	# course ID = DEPT ### (ex: CHEM 313)
	def get_info(course_id)
		# dept, number = course_id.split()
		
		# @course_dict[dept].find{|x| x.include? number }
		# course_page = next(x[2] for x in @course_dict[dept] if number in x[0])
		# return util.course_info(course_page)
	end
end


end
