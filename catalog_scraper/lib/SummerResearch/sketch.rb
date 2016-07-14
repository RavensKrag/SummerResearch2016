#!/usr/bin/env ruby
# encoding: utf-8

module SummerResearch

DATA_DIR = File.join(PATH_TO_ROOT, 'bin', 'data')

class Sketch
class << self



# Roughly imported from python sketch on how to meaningfully extract degree requirements
# was only ever called from one pathway in rakefile. that pathway has been removed.
# dependencies: foo1
def foo6(degrees)
	url = degrees["Computer Science, BS"]
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
def foo7(degrees, program_name)
	url = degrees[program_name]
	
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





end
end
end
