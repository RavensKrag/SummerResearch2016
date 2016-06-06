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
url = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
degree_dict = util.find_possible_degrees(url, [
						"Computer Science",
						"Information Technology",
						"Electrical Engineering",
						"Biology",
						"Psychology"
					])
# print_dictionary(degree_dict)

filepath = "./tmp/degrees_offered.txt"
file = open(filepath, "w")

for k in sorted(degree_dict.iterkeys()):
	file.write(k.encode('utf8'))
	file.write("\n")

file.close



# url = degree_dict["Computer Science, BS"])
# url = degree_dict["Applied Computer Science, BS"]
# url = degree_dict["Biology, BA"]
# url = degree_dict["Biology, BS"]
url = degree_dict["Psychology, BA"]

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


print "CS 330"
util.course_info("preview_course.php?catoid=29&coid=302788&print")

print "STAT 344"
util.course_info("preview_course.php?catoid=29&coid=306778&print")

print "PSYC 320"
util.course_info("preview_course.php?catoid=29&coid=306130&print")


course_dict = {
	"CS":   util.search_by_department("CS"),
	"BIOL": util.search_by_department("BIOL"),
	"PSYC": util.search_by_department("PSYC")
}

print course_dict["CS"][0]




# list comprehension to get the first item that matches critera in list
# really want a differet way of doing this...
# like, why is the word "next"?
# 
# http://stackoverflow.com/questions/9542738/python-find-in-list
# http://stackoverflow.com/questions/9868653/find-first-list-item-that-matches-criteria
course_page = next(x[2] for x in course_dict["CS"] if "101" in x[0])
# remember that the tuple is (course id, short desc, link)
print course_page




def get_info(storage, dept, number):
	course_page = next(x[2] for x in storage[dept] if number in x[0])
	return util.course_info(course_page)


dept, number = "CS 101".split()
get_info(course_dict, dept, number)

# I mean, course names are just 2-4 capital letters, and a 3-digit number
# you could probably scan with regex and pull that out pretty easily?




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
