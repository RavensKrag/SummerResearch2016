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
	def foo1(self):
		url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
		self.degree_dict = util.find_possible_degrees(url, [
								"Computer Science",
								"Information Technology",
								"Electrical Engineering",
								"Biology",
								"Psychology"
							])
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
		# url = self.degree_dict["Computer Science, BS"])
		# url = self.degree_dict["Applied Computer Science, BS"]
		# url = self.degree_dict["Biology, BA"]
		# url = self.degree_dict["Biology, BS"]
		url = self.degree_dict["Psychology, BA"]
		
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
		self.foo5( ["CS", "BIOL", "PSYC"] )
		
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
	
	
	# --- helper methods
	def get_info(self, dept, number):
		course_page = next(x[2] for x in self.course_dict[dept] if number in x[0])
		return util.course_info(course_page)
# ====================


x = Foo()

# x.foo1()
# x.foo2()
# x.foo3()
x.foo4()





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
