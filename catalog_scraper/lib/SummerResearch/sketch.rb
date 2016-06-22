module SummerResearch

class << self


# this is basically a pathway.
# 
# dependencies: foo1
# get the list of courses for one program, based on its name
def foo2(degree_name)
	url = @degrees[degree_name]
	# url = self.degree_dict["Applied Computer Science, BS"]
	# url = self.degree_dict["Biology, BA"]
	# url = self.degree_dict["Biology, BS"]
	# url = self.degree_dict["Psychology, BA"]
	
	course_list = degree_requirements(url)
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



# this is a very simple routine. does not need to be it's own function

# similar to the tests (very similar to foo12),
# but this is an actual procedure
# (subroutine. used to generate intermediates. should probably parameterize output path?
# (or maybe just return data, and not write to file)
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



# dependencies: none
# get possible degree program requrement lists
def foo1(list_of_degrees)
	url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
	@degrees = search_programs_of_study(url, list_of_degrees)
	
	count = @degrees.keys.size
	puts "#{count} programs found for search query."
	
	filepath = File.expand_path("./programs_of_study.yaml", DATA_DIR)
	puts "Writing to file '#{filepath}'"
	
	File.open(filepath, 'w') do |f|
		f.puts @degrees.to_yaml
	end
end

def foo5(list_of_deparments)
	@courses = Hash.new
	
	list_of_deparments.each do |dept|
		@courses[dept] = courses_in_department(dept)
	end
end


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
	
	# TODO: if department is not found, error should alert the user that list of courses needs to be pulled down from the Catalog for that department before asking for a course.
	
	return SummerResearch::CourseInfo.new(course).fetch
end



# get program requirements (more than just course dependencies)
# dependencies: foo1
def foo6
	url = @degrees["Computer Science, BS"]
	# url = @degrees["Applied Computer Science, BS"]
	# url = @degrees["Biology, BA"]
	# url = @degrees["Biology, BS"]
	# url = @degrees["Psychology, BA"]
	
	
	# find a bunch of tags to collect,
	# and then print those tags to file, preserving the order from the document
	fragment = requirements_subtree(url)
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



# just get a list of courses from the program of study page.
# not the full logic as in foo6, just a list of links
# (I think this gets a lists of the course link struct objects? not just the URLs IIRC)
# dependencies: foo1
# precursors: foo6, required_courses, degree_requirements, foo2
def foo7(program_name)
	url = @degrees[program_name]
	
	# util.degree_requirements(url)
	
	# TODO: consider moving this code back under util.degree_requirements if it does not use any of shared state, but keep it here for now for ease of writing
	
	
	fragment = requirements_subtree(url)
	
	# TODO: need to improve this selector. catching some false positives.
	# wait, variable 'fragment' is a list...
	course_list = get_all_weird_link_urls(fragment)
	
	
	
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







# private



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
