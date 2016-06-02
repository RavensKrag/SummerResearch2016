# use 'pip' for package management
# (very similar to 'gem' in Ruby)

import requests
from bs4 import BeautifulSoup

import re

import itertools
import operator
import csv





# write the data to the file
def write_html_to_file(filepath, data):
	file = open(filepath, "w")
	
	# BeautifulSoup basically chucks the original HTML out the window after processing.
	# Need to prettify it if you want indentation, otherwise it becomes an unreadable mess.
	# (everything on one line)
	
	
	# print "--- WRITE TO FILE ---"
	# print type(data)
	# print "---------------------"
	
	
	
	# TODO: figure out a better way to handle both lists and single items
	
	# must encode string to unicode, or attempts to write ASCII which is bad
	if isinstance(data, list):
		for x in list(data):
			foo = x.prettify()
			unicode_string = foo.encode('utf8')
			file.write(unicode_string)
	else:
		foo = data.prettify()
		unicode_string = foo.encode('utf8')
		
		file.write(unicode_string)
	
	file.close

# following CSV methods take code from the python CSV documentation:
# source: https://docs.python.org/2/library/csv.html
def write_csv(filepath, list):	
	with open(filepath, 'w') as csvfile:
		w = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
		for row in list:
			w.writerow(row)
	
def read_csv(filepath, list):
	with open('filepath', 'rb') as csvfile:
		r = csv.reader(csvfile)
		for row in r:
			print ', '.join(row)

# remove duplicates and keep order (in ruby this is Array#uniq)
# src: http://stackoverflow.com/questions/479897/how-to-remove-duplicates-from-python-list-and-keep-order
def uniq(input_list):
	return list(map(operator.itemgetter(0), itertools.groupby(input_list)))


def get_soup(url):
	r = requests.get(url)

	content = r.content

	soup = BeautifulSoup(content, "html.parser")
	
	return soup

def fix_br_tags(input_file, output_file):
	f = open(input_file,'r')
	data = f.read()
	f.close()
	
	new_data = data.replace("</br>","")
	new_data = data.replace("<br>","<br></br>")
	
	f = open(output_file,'w')
	f.write(new_data)
	f.close()

def get_scoup_from_file(filepath):
	f = open(filepath,'r')
	
	content = f.read()
	soup = BeautifulSoup(content, "html.parser")
	
	f.close()
	
	return soup

def find_possible_degrees(url):
	soup = get_soup(url)

def required_courses(url):
	# NOTE: beautiful soup (python) always returns a list from queries, 
	#       as opposed to nokogiri (ruby) which will return a single item
	#       if there is only one item in the list. That's why BS4 requires
	#       so many more of these "[0]" calls.
	
	soup = get_soup(url)
	
	main_table = soup.select("td.block_content_outer")[0]
	# select returns a list of nodes, if you cast the node to a string and print it,
	# it will print the subtree under that DOM node
	# print type(main_table)
	
	title       = main_table.select('h1#acalog-content')[0].contents[0]
	banner_code = main_table.select('td.block_content p')[1].select('strong')[0].contents[0]
	
	
	h2 = main_table.select('td.block_content p')[2]
	links = h2.select('a')
	links[1]
	
	
	# Python note: [u'Hello world'] is a list, including the unicode string "hello world"
	print title 
	print banner_code
	
	
	school      = links[0]
	department  = links[1]
	description = h2 # this is not correct, but a good start
	
	# WARNING: mixed content. No good way to just grab the description.
		# Degree name
		# banner code
		# school
		# department
		# description
	# are all at the same level of the tree.
	
	write_html_to_file("./segment.html", main_table)
	
	
	
	
	description_container = main_table.select('td.block_content > table tr')[0]
	# contains sections described in comment above
	
	
	
	requirements = main_table.select('td.block_content > table tr > td')[3]
	# print(requirements.name) # td
	requirements = list(requirements.children)[1]
	# strip off the "td" element. "td" will not appear in browser either way.
	
	
	# should contain the actual course info
	write_html_to_file("requirements.html", requirements)
	
	
	
	
	# ruby:   if, elsif, else
	# python: if, elif, else
	a = -1
	b = -1
	for i, req in enumerate(requirements.children): # use enumerate() to get i AND value
		text = req.get_text()
		if "Degree Requirements" in text:
			print "START"
			print text
			print i
			a = i
		elif "Total:" in text:
			print text
			print i
			print "END"
			b = i
	
	# different end markers for different departments
	# (note that Psych BA uses "Total: " to show subtotals)
	# Really want to check for the substrings "Total:" and "120 credits"
	
	# program     target end string                     range
	# -------     -------------------                   ------
	# CS BS       "Total: 120 credits"                  (0..2)
	# Bio BA      "Degree Total: Minimum 120 credits"   (0..5)
	# Psych BA    "Degree Total: Minimum 120 credits"   (?..?)
	
	# NOTE: section headings for "Mason Core" and "BA Requirements" may vary
	
	
	
	
	# TODO: raise exception if a != 0
		# I assume that it should always be 0, so
		# if that fundamental underlying assumption is broken,
		# it is possible that many things have actually broken.
	
	# TODO: raise exception if a == -1 OR b == -1
		# this means that the values were never initialized
		# you need BOTH to be set
	
	# TODO: figure a better way of getting the start and end points, a and b
	
	
	
	
	# ruby: arry[0..3]  # inclusive of both ends
	# python: arry[0:4] # inclusive of bottom end, exclusive of top end
	fragment = list(requirements.children)[(a+1):b]
	
	write_html_to_file("fragment.html", fragment)
	
	
	
	# TODO: need to improve this selector. catching some false positives.
	# wait, variable 'fragment' is a list...
	
	links = [x.findAll("a",{"onclick":True}) for x in fragment]
	
	# NOTE: splat operator works in Python too, apparently
	# for a in itertools.chain(*links):
	# 	print type(a)
	# 	title, url = extract_link(a)
	# 	print "%s, %s" % (title, url)
	# 	print "================="
	
	data = [extract_link(anchor_tag) for anchor_tag in itertools.chain(*links)]
	return data
	
	
	
	

# given a "link" from the course overview page, get an actual HTML link
# html_anchor_node: a BS4 node object that describes the <a> tag with the link data in it
def extract_link(html_anchor_node):
	course_title = html_anchor_node.contents[0]
	description  = ""
	parts = course_title.split(" - ")
	if len(parts) == 2:
		course_title = parts[0]
		description  = parts[1]
	else:
		course_title = parts[0]
		
	print course_title
	# NOTE: some times the course title is given, and sometimes it is not
	# ex) CS 367 - Computer Systems and Programming
	#       vs
	#     ENGH 302
	
	
	# print type(html_anchor_node)
	# print html_anchor_node.name
	script = html_anchor_node['onclick']
	print script
	
	
	# there are two formats:
	# showCourse()
	# acalogPopup()
	# 
	# showCourse('29', '302347',this, 'a:2:{s:8:~location~;s:7:~program~;s:4:~core~;s:6:~245513~;}'); return false;
	# acalogPopup('preview_course.php?catoid=29&coid=318028&print', '3', 770, 530, 'yes');return false;
	
	regexp_a = r"showCourse\('(.+?)'\, '(.+?)',this,"
	regexp_b = r"acalogPopup\('(.+?)'.*"
	url = ""
	if "showCourse" in script:
		# a = 29
		# b = 302347
		
		match = re.match(regexp_a, script)
		a = match.group(1) # TODO: convert both matches to actual numbers maybe?
		b = match.group(2) #       idk, just going to convert back to string and use in URL again
		print [a, b]
		
		url = "preview_course.php?catoid=%s&coid=%s&print" % (a,b)
		print url
		
	elif "acalogPopup" in script:
		match = re.match(regexp_b, script)
		a = match.group(1)
		print a
		url = a
	
	print "==="
	
	return (course_title, description, url)


# def extract_showCourse():
	

# def extract_acalogPopup():


def get_dependencies(catalog_url_fragment):
	url = "http://catalog.gmu.edu/" + catalog_url_fragment
	
	# <strong>Prerequisite(s):</strong>
	# also corequites, etc
	# if mentions of prerequisites come up later, they will not be marked with <strong>
	# NOTE: much like how the general program page indents things, but they are not considered under a branch in the markup (just div with styling), <strong> creates visual separation without actual nesting in the DOM. May want to run similar preprocessing on these two segments.
	# NOTE: notes section usually explains extra requirements (take in x semester, take before x point in time, restricted to these people)
	# NOTE: PSYC 300 / 301 noted in program overview, supposed to be taken before Junior year, but that is NOT noted on the course themselves. Thus, if there is special info on the course page, it will be under NOTES, but it is not necessarily true that all course info will be in one place.
	# NOTE: some classes note in which semesters they are offered
	#       (ex STAT 344 says "When Offered: Fall, Spring, Summer")
	
	print url
	soup = get_soup(url)
	chunk = soup.select("td.block_content_popup")[0]
	
	print type(chunk)
	filepath = "./course.html"
	write_html_to_file(filepath, chunk)
	# table      <-- skip this
	# h1         <-- name of course again
	# * data you actually care about (some formatting markup, no semantic tree-like structure)
	# p > br     <-- end of meaningful section
	# some links to the catalog
	
	# TODO: need to pre-process this file, in order to replace <br> with <br /> and then re-load that. BS4 not properly processing <br> tags, and it's making things very difficult...
	# BS4 misinterprets the <br> tag
	# it is generally assumed that <br> == <br />, but BS4 seems fairly strict about things
	
	
	
	
	# =======
	input_file  = filepath
	output_file = "./course_processed.html"
	fix_br_tags(input_file, output_file)
	# =======
	
	
	
	
	soup = get_scoup_from_file(output_file)
	chunk = soup.select("td.block_content_popup")[0]
	write_html_to_file("./course_processed_bs4.html", chunk)
	
	# [0] nothing
	# [1] navigation
	# [2] nothing
	# [3] h1
	# [4] text after the h1 (mixed content) ex: "Credits: 2"
	# 
	
	
	# print type(chunk)
	# print chunk.contents[5]
	
	
	
	# <strong>Corequisite(s):</strong>
	# CS 112.
	# <br>
	# ---
	# title in <strong> tags
	# content
	# <br>

	


	

# TODO: now that you have the links to each individual course, for one course, extract dependency information.
	# prerequisites
	# co requisites
	# certain number of courses required before taking
	# requirement to take at a certain time (duing first semester, before Junior year, etc)
	# 
	# eventually want to understand "systemic requirements" like that certain classes are only offered in Fall / only in Spring etc 
# TODO: store all of this information in some easily accessible format





# main
url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28260&returnto=6270" # CS BS
# url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28210&returnto=6270" # biol BA
# url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28492&returnto=6270" # Psych BA
course_list = required_courses(url)


# TODO: remove dupicate entries in the list of courses
	# not just as simple as removing duplicates from list
	# need to remove when two tuples have the same first element
	# also - want to keep original ordering
# NOTE: this may not be necessary if the selection filter on links is improved


write_csv("./required_courses.csv", course_list)


name, desc, url_fragment = course_list[0]
get_dependencies(url_fragment)



# parse programs of study page to get programs
# parse each of those to get the courses
# output course information and dependencies

# another pass to figure out the program requirements?
# higher-level dependecies than just what course requires what.
# Need to understand that you need a certain number of courses from particular categories.
