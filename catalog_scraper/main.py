#!/usr/bin/env python
# -*- coding: utf-8 -*-


# use 'pip' for package management
# (very similar to 'gem' in Ruby)


# libraries
import requests
import bs4
from bs4 import BeautifulSoup

import re

import itertools
import operator
import csv

# files
import util




# ==== main ====
class Foo(object):
	def __init__(self):
		self.storage = dict()
	
	
	# dependencies: none
	# get possible degree program requrement lists
	def foo1(self, list_of_degrees):
		url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
		self.degree_dict = util.find_possible_degrees(url, list_of_degrees)
		# print_dictionary(degree_dict)
		
		filepath = "./tmp/degrees_offered.txt"
		file = open(filepath, "w")

		for k in sorted(self.degree_dict.iterkeys()):
			file.write(k.encode('utf8'))
			file.write("\n")
		
		file.close
	
	
	# dependencies: foo1
	# get the list of courses for one program, based on it's name
	def foo2(self):
		url = self.degree_dict["Computer Science, BS"]
		# url = self.degree_dict["Applied Computer Science, BS"]
		# url = self.degree_dict["Biology, BA"]
		# url = self.degree_dict["Biology, BS"]
		# url = self.degree_dict["Psychology, BA"]
		
		course_list = util.required_courses(url)
		
		
		# TODO: remove dupicate entries in the list of courses
			# not just as simple as removing duplicates from list
			# need to remove when two tuples have the same first element
			# also - want to keep original ordering
		# NOTE: this may not be necessary if the selection filter on links is improved
		
		
		util.write_csv("./tmp/required_courses.csv", course_list)
		# course_list = read_csv("./required_courses.csv")
		
		
		name, desc, url_fragment = course_list[0]
		print name
		util.course_info(url_fragment)
	
	
	# dependencies: foo1
	# test getting specific course info, based on URL fragment
	# (special cases of methodogly from foo2)
	def foo3(self):
		print "CS 330"
		util.course_info("preview_course.php?catoid=29&coid=302788&print")
		
		print "STAT 344"
		util.course_info("preview_course.php?catoid=29&coid=306778&print")
		
		print "PSYC 320"
		util.course_info("preview_course.php?catoid=29&coid=306130&print")
	
	# dependencies: none
	def foo5(self, list_of_deparments):
		self.course_dict = dict()
		
		for dept in list_of_deparments:
			self.course_dict[dept] = util.search_by_department(dept)
		
		# self.course_dict = dict( [ (dept, util.search_by_department(dept)) for dept in list_of_deparments ] )
	
	
	# dependencies: foo5
	# pull down list of courses by seaching by ID, and then pull down specifics
	def foo4(self):		
		print self.course_dict["CS"][0]
		
		# list comprehension to get the first item that matches critera in list
		# really want a differet way of doing this...
		# like, why is the word "next"?
		# 
		# http://stackoverflow.com/questions/9542738/python-find-in-list
		# http://stackoverflow.com/questions/9868653/find-first-list-item-that-matches-criteria
		course_page = next(x[2] for x in self.course_dict["CS"] if "101" in x[0])
		# remember that the tuple is (course id, short desc, link)
		print course_page
		
		
		dept, number = "CS 101".split()
		self.get_info(dept, number)
		
		# I mean, course names are just 2-4 capital letters, and a 3-digit number
		# you could probably scan with regex and pull that out pretty easily?
	
	
	# dependencies: foo1
	def foo6(self):
		url = self.degree_dict["Computer Science, BS"]
		# url = self.degree_dict["Applied Computer Science, BS"]
		# url = self.degree_dict["Biology, BA"]
		# url = self.degree_dict["Biology, BS"]
		# url = self.degree_dict["Psychology, BA"]
		
		
		# find a bunch of tags to collect,
		# and then print those tags to file, preserving the order from the document
		fragment = util.requirements_subtree(url)
		print len(fragment)
		
		x = []
		x += [x.select("p") for x in fragment]
		x += [x.select( ", ".join( ["h%d" % (i) for i in range(1,12)] ) ) for x in fragment]
		
		
		collection = set({})
		for tag in itertools.chain.from_iterable(x):
			collection.add(tag)
		
		
		x = [ [child for child in head.descendants if child in collection] for head in fragment]
		
		print x
		
		util.write_html_to_file("./tmp/human.html", x)
		
		
		# sometimes you see a <strong> sometimes you see a <strong><u> which is really bad...
	
	# dependencies: foo1
	# precursors: foo6, util.required_courses, util.degree_requirements
	def foo7(self, program_name):
		url = self.degree_dict[program_name]
		
		
		# fragment = util.requirements_subtree(url)
		
		util.degree_requirements(url)
		
		return []
	
	# backend dependency tree construction
	def foo8(self, list_of_courses):
		pass
	
	# query
	def foo9(self, class_dependencies, target_course):
		pass
	
	# visualization
	def foo10(self, class_dependencies, output_filepath):
		pass
	
	
	# --- helper methods
	
	# dependencies: foo5
	def get_info(self, dept, number):
		course_page = next(x[2] for x in self.course_dict[dept] if number in x[0])
		return util.course_info(course_page)
# ====================




x = Foo()


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
	x.foo5( ["CS", "BIOL", "PSYC"] )
	
	
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
