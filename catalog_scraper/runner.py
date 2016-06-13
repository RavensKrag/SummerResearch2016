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
		
		
		self.get_info("CS 101")
		
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
	# precursors: foo6, util.required_courses, util.degree_requirements, foo2
	def foo7(self, program_name):
		url = self.degree_dict[program_name]
		
		# util.degree_requirements(url)
		
		# TODO: consider moving this code back under util.degree_requirements if it does not use any of shared state, but keep it here for now for ease of writing
		
		
		fragment = util.requirements_subtree(url)
		
		# TODO: need to improve this selector. catching some false positives.
		# wait, variable 'fragment' is a list...
		links = [x.findAll("a",{"onclick":True}) for x in fragment]
		
		
		course_list = [util.extract_link(anchor_tag) for anchor_tag in itertools.chain.from_iterable(links)]
		
		
		
		# TODO: remove dupicate entries in the list of courses
			# not just as simple as removing duplicates from list
			# need to remove when two tuples have the same first element
			# also - want to keep original ordering
		# NOTE: this may not be necessary if the selection filter on links is improved
		
		
		util.write_csv("./tmp/required_courses.csv", course_list)
		
		
		
		
		self.get_info("CHEM 313")
		# return [course_list[0]]
		
		sample = [
			(
				"CS 101",
				"Preview of Computer Science",
				"preview_course.php?catoid=29&coid=302776&print"
			),
			(
				"CS 465",
				"Computer Systems Architecture",
				"preview_course.php?catoid=29&coid=302800&print"
			),
			(
				"CS 475",
				"Concurrent and Distributed Systems",
				"preview_course.php?catoid=29&coid=302803&print"

			),
			
		]
		return sample
	
	# Backend dependency graph construction.
	# given a list of courses, figure out all of the dependencies
	def foo8(self, list_of_courses):
		# course_list = util.read_csv("./tmp/required_courses.csv")
		
		out = dict()
		
		for course in list_of_courses:
			name, desc, url_fragment = course
			
			dependencies = []
			print self.get_dependencies(course)
			out[name] = dependencies
		
		return out
	
	# query
	def foo9(self, class_dependencies, target_course):
		pass
	
	# visualization
	def foo10(self, class_dependencies, output_filepath):
		pass
	
	
	# --- helper methods
	
	# dependencies: foo5
	# course ID = DEPT ### (ex: CHEM 313)
	def get_info(self, course_id):
		dept, number = course_id.split()
		
		course_page = next(x[2] for x in self.course_dict[dept] if number in x[0])
		return util.course_info(course_page)
	
	def get_dependencies(self, course_tuple):
		name, desc, url_fragment = course_tuple
		
		print name
		info = util.course_info(url_fragment) # NOTE: this prints out the data it has scraped
		
		# TODO: separate prerequisites from corequisites
		dependencies = []
		
		# NOTE: python throws error rather than returning nil when key not found in dict
		# KeyError: 'Prerequisite(s)'
		a = ""
		try:
			a = info["Prerequisite(s)"]
		except KeyError:
			pass
		
		b = ""
		try:
			b = info["Corequisite(s)"]
		except KeyError:
			pass
		
		
		# NOTE: in the case of mulitple prerequsites from the same department, ommit the department code for subsequent elements.
		# ex) CS 310 and 367
		
		# NOTE: Mason Core courses have some other format, as they are not actually individual courses, but IDs that reference a SET of courses.
		regex = r"(\s*?)((\w+) (\d\d\d)(.*?)(\d\d\d)*)+?"
		if a != "":
			match = re.findall(regex, info["Prerequisite(s)"])
			print "=== regex"
			print len(match)
			print match
			# print match.group(1)
			# print match.group(2)
			# print match.group(3)
			# print match.group(4)
			print "========="
		
		if b != "":
			match = re.findall(regex, info["Corequisite(s)"])
			print "=== regex"
			print len(match)
			print match
			# print match.group(1)
			# print match.group(2)
			# print match.group(3)
			# print match.group(4)
			print "========="
		
		# re.match(r"(.+?)((\w*) (\d\d\d))*", "Grade of C or better in CS 367.").group(2)
		
		print name
		print "Prerequisites: %s" % (a)
		print "Corequisites:  %s" % (b)
		
		return " ".join([a,b]).strip()
# ====================
