#!/usr/bin/env ruby
# encoding: utf-8

module SummerResearch

DATA_DIR = File.join(PATH_TO_ROOT, 'bin', 'data')


class Main
	def initialize
		@degree_hash = nil
	end
	
	
	
	# dependencies: none
	# get possible degree program requrement lists
	def foo1(list_of_degrees)
		url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
		@degree_hash = SummerResearch.search_programs_of_study(url, list_of_degrees)
		
		count = @degree_hash.keys.size
		puts "#{count} programs found for search query."
		
		filepath = File.expand_path("./programs_of_study.yaml", DATA_DIR)
		puts "Writing to file '#{filepath}'"
		
		File.open(filepath, 'w') do |f|
			f.puts @degree_hash.to_yaml
		end
	end
		
	# dependencies: foo1
	# get the list of courses for one program, based on its name
	def foo2(degree_name)
		url = @degree_hash[degree_name]
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
	
	# dependencies: foo2 (2 => 1)
	def foo11(course_list)
		name, desc, url_fragment = course_list[0]
		puts name
		
		info = SummerResearch.course_info(url_fragment)
		Utilities.write_to_file('./course_info.yaml', info.to_yaml)
		
		
		return nil
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
		end
	end
	
	# dependencies: none
	def foo5(list_of_deparments)
		@course_hash = Hash.new
		
		list_of_deparments.each do |dept|
			@course_hash[dept] = SummerResearch.search_by_department(dept)
		end
	end
	
	# dependencies: foo5
	# check the cache for info on a particular course
	def foo4
		print @course_dict["CS"][0]
		
		@course_dict["CS"].find{  |x| x[0].include?  }
		
		# list comprehension to get the first item that matches critera in list
		# really want a differet way of doing this...
		# like, why is the word "next"?
		# 
		# http://stackoverflow.com/questions/9542738/python-find-in-list
		# http://stackoverflow.com/questions/9868653/find-first-list-item-that-matches-criteria
		course_page = next(x[2] for x in @course_dict["CS"] if "101" in x[0])
		# remember that the tuple is (course id, short desc, link)
		print course_page
		
		
		dept, number = course_id.split()
		
		@course_dict[dept].find{|x| x.include? number }
		course_page = next(x[2] for x in @course_dict[dept] if number in x[0])
		
		return util.course_info(course_page)
	end
	
	def foo6
		
	end
	
	def foo7
		
	end
	
	def foo8
		
	end
	
	def foo9
		
	end
	
	def foo10
		
	end
	
	
	
	
	private
	
	def helper
		
	end
	
	# dependencies: foo5
	# course ID = DEPT ### (ex: CHEM 313)
	def get_info(course_id)
		dept, number = course_id.split()
		
		@course_dict[dept].find{|x| x.include? number }
		course_page = next(x[2] for x in @course_dict[dept] if number in x[0])
		return util.course_info(course_page)
	end
end


end
