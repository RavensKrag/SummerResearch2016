#!/usr/bin/env python
# -*- coding: utf-8 -*-


# use 'pip' for package management
# (very similar to 'gem' in Ruby)


import runner as Run


# ==== main ====
x = Run.Foo()


def pathway1(x):
	x.foo1([
		"Computer Science",
		"Information Technology",
		"Electrical Engineering",
		"Biology",
		"Psychology"
	])
	x.foo2()
	x.foo3()
	
def pathway2(x):
	x.foo5( ["CS", "BIOL", "PSYC"] )
	x.foo4()

def pathway3(x):
	x.foo1([
		"Computer Science",
		"Information Technology",
		"Electrical Engineering",
		"Biology",
		"Psychology"
	])
	x.foo6()

def pathway4(x):
	# pull down a bunch of data
	x.foo1([
		"Computer Science",
		"Information Technology",
		"Electrical Engineering",
		"Biology",
		"Psychology"
	])
	x.foo5( ["CS", "BIOL", "CHEM", "PSYC"] )
	# TODO: cache 1 and 5 to speed up evaluation
	
	
	[
		"Computer Science, BS",
		"Applied Computer Science, BS",
		"Biology, BA",
		"Biology, BS",
		"Psychology, BA"
	]
	
	# take one degree program, and walk the dependencies for all courses in the degree
	course_list = x.foo7("Computer Science, BS")  # get all relevant courses
	class_dependencies = x.foo8(course_list)      # construct all dependencies
	
	output_filepath = ""
	x.foo10(class_dependencies, output_filepath)  # visualize the dependency graph
	
	
	# query: what is the chain of courses that lead up to this course? 
	x.foo9(class_dependencies, "CS 465")
	# => [CS 367, ECE 301, CS 262, CS 211, CS 112, MATH 113, CS 101?]
	
	# TODO: This is actually not properly a list, it is a subgraph. Some dependencies do not lie along the main path. How do you display that information?
	# NOTE: "ECE 301" is the old name, IIRC



# pathway1(x)
# pathway2(x)
# pathway3(x)
pathway4(x)
	







# parse programs of study page to get programs
# parse each of those to get the courses
# output course information and dependencies

# another pass to figure out the program requirements?
# higher-level dependecies than just what course requires what.
# Need to understand that you need a certain number of courses from particular categories.



# TODO: now that you have the links to each individual course, for one course, extract dependency information.
	# prerequisites
	# co requisites
	# certain number of courses required before taking
	# requirement to take at a certain time (duing first semester, before Junior year, etc)
	# 
	# eventually want to understand "systemic requirements" like that certain classes are only offered in Fall / only in Spring etc 
# TODO: store all of this information in some easily accessible format
