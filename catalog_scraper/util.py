#!/usr/bin/env python
# -*- coding: utf-8 -*-


# use 'pip' for package management
# (very similar to 'gem' in Ruby)

import requests
import bs4
from bs4 import BeautifulSoup

import re

import itertools
import operator
import csv



# ===
# === Generalizable helper functions
# === (doesn't pertain to just this project)
# ===

# ruby-style pretty printing of dictionary
def print_dictionary(dict):
	print "{"
	for k,v in dict.iteritems():
		print "  %s => %s" % (k, v)
	print "}"

# write the data to the file
def write_html_to_file(filepath, data):
	file = open(filepath, "w")
	
	# BeautifulSoup basically chucks the original HTML out the window after processing.
	# Need to prettify it if you want indentation, otherwise it becomes an unreadable mess.
	# (everything on one line)
	
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
	
def read_csv(filepath):
	f = open(filepath, 'rb')
	r = csv.reader(f)
	out = [row for row in r]
	f.close
	
	return out

# remove duplicates and keep order (in ruby this is Array#uniq)
# src: http://stackoverflow.com/questions/479897/how-to-remove-duplicates-from-python-list-and-keep-order
def uniq(input_list):
	return list(map(operator.itemgetter(0), itertools.groupby(input_list)))










# ===
# === Manage HTML stuff
# ===

def get_soup(url):
	r = requests.get(url)

	content = r.content

	soup = BeautifulSoup(content, "html.parser")
	
	return soup

def get_soup_from_file(filepath):
	f = open(filepath,'r')
	
	content = f.read()
	soup = BeautifulSoup(content, "html.parser")
	
	f.close()
	
	return soup

def fix_singleton_tags(tag_object):
	# TODO: create intermediate files HERE, as a debug procedure
	
	input_file   = "./tmp/course.html"
	intermediate = "./tmp/course_processed.html"
	output_file  = "./tmp/course_processed_bs4.html"
	
	# TODO: eliminate intermediate files, and just perform transform in-memory
	
	# NOTE: write 3 files:
	# 	raw input parsed by BS4
	# 	input with replacement
	# 	replaced code that was run through BS4 a second time (to make sure replacement worked)
	
	# NOTE: writing to file and reading back eliminates potential weirdness of having a list as input, instead of a single tag, but I think that should never actually happen?
	
	
	# html tree to text file
	write_html_to_file(input_file, tag_object)
	
	# text file to data
	f = open(input_file,'r')
	data = f.read()
	f.close()
	
	# replacement of malformed tags, in memory
	singletons = ["hr", "br"] # list your singletons here, and fix them all
	
	new_data = data # need this, because of mulitple iterations of loop
	for tag in singletons: 
		new_data = new_data.replace("</%s>" % (tag), ""
		                  ).replace( "<%s>" % (tag), "<%s />" % (tag)
		                  )
	
	# write edited file back to disk
	f = open(intermediate,'w')
	f.write(new_data)
	f.close()
	
	# load edited file, and return new subtree
	soup = get_soup_from_file(intermediate)
	tag_object = soup.contents[0]
	write_html_to_file(output_file , tag_object)
	
	return tag_object

# given a "link" from the course overview page, get an actual HTML link
# html_anchor_node: a BS4 node object that describes the <a> tag with the link data in it
def extract_link(html_anchor_node):
	course_title = html_anchor_node.contents[0]
	description  = ""
	parts = course_title.encode('utf8' # operation fails if you skip the encode step
	                   ).replace(" - ", " - " # replace em-dash (long one) with en-dash (ASCII)
	                   ).split(" - ")
	# NOTE: I think this may convert the string to ASCII? that could have serious side-effects
	# TODO: look more into how .encode() works
	# 
	# to be perfectly clear, at the end of this, "parts" appears to no longer be a unicode string (not printed as u'foo' when printng, but rather just 'foo')
	
	# NOTE: something seems to be mangling the em-dash found in some pages on the Catalog
	# ex)
	# output:   BIOL 103Â -Â Introductory Biology I
	# expected: BIOL 103  -  Introductory Biology I
	# (the bottom example here actually uses an en-dash ASCII character)
	
	# an noted in one article,
	# it is likely this is a unicode problem. the character should most likely appear as an em-dash, but it is getting mangled.
	# src: https://markmcb.com/2011/11/07/replacing-ae%E2%80%9C-ae%E2%84%A2-aeoe-etc-with-utf-8-characters-in-ruby-on-rails/
	
	# looks like maybe python just doesn't handle unicode very well?
	# src: http://stackoverflow.com/questions/19528853/python-removing-particular-character-u-u2610-from-string
	
	
	if len(parts) == 2:
		course_title = parts[0]
		description  = parts[1]
	else:
		course_title = parts[0]
		
	# print course_title
	# NOTE: some times the course title is given, and sometimes it is not
	# ex) CS 367 - Computer Systems and Programming
	#       vs
	#     ENGH 302
	
	
	# print type(html_anchor_node)
	# print html_anchor_node.name
	script = html_anchor_node['onclick']
	# print script
	
	
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
		# print [a, b]
		
		url = "preview_course.php?catoid=%s&coid=%s&print" % (a,b)
		# print url
		
	elif "acalogPopup" in script:
		match = re.match(regexp_b, script)
		a = match.group(1)
		# print a
		url = a
	else:
		print "WARNING: unknown link format detected: "
		print script
	
	# print "==="
	
	return (course_title, description, url)


# def extract_showCourse():
	

# def extract_acalogPopup():






# ===
# === Get stuff done
# ===

def find_possible_degrees(url, target_fields):
	soup = get_soup(url)
	
	# --- the list of programs is the last list on the page
	segment = soup.select("ul")[-1]
	write_html_to_file("./tmp/degree_list.html", segment)
	
	# --- get the relevant string names, and the links to the requirements pages
	degrees = [x for x in segment.children if isinstance(x, bs4.element.Tag)]
	degrees = [(x.a.string.lstrip(), x.a["href"]) for x in degrees]
	# print degrees
	
	# --- convert to dictionary
	degrees = dict(degrees)
	# print degrees
	
	# --- figure out what degrees you are looking for
	# includy any degree in the catalog if
	# it includes at least one of the query sequences in the "target_fields" list
	fields = [x for x in degrees.iterkeys() if any([y for y in target_fields if y in x])]
	# print fields
	
	# --- return a dictionary with only the relevant degrees inside
	return dict( [ (x, "http://catalog.gmu.edu/" + degrees[x]) for x in fields ] )


# given a url to the page in the catalog that lists all the requirements for a course,
# extract tuples of the form (course ID, description, url_frament)
# 'url_fragement' is a relative link from the catalog page, showing where to get specific info
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
	
	write_html_to_file("./tmp/segment.html", main_table)
	
	
	
	
	description_container = main_table.select('td.block_content > table tr')[0]
	# contains sections described in comment above
	
	
	
	requirements = main_table.select('td.block_content > table tr > td')[3]
	# print(requirements.name) # td
	requirements = list(requirements.children)[1]
	# strip off the "td" element. "td" will not appear in browser either way.
	
	
	# should contain the actual course info
	write_html_to_file("./tmp/requirements.html", requirements)
	
	
	
	
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
	
	write_html_to_file("./tmp/fragment.html", fragment)
	
	
	
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


# extract the info out of details page from the catalog
def course_info(catalog_url_fragment):
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
	
	filepath = "./tmp/course.html"
	write_html_to_file(filepath, chunk)
	
	# BS4 does not understand that <br> == <br />
	# and so tries to fix the open <br> by inserting </br> tags (which are not real HTMl tags)
	chunk = fix_singleton_tags(chunk)
	
	
	# table      <-- skip this
	# h1         <-- name of course again
	# * data you actually care about (some formatting markup, no semantic tree-like structure)
	# p > br     <-- end of meaningful section
	# some links to the catalog
	
	# [0] nothing
	# [1] navigation
	# [2] nothing
	# [3] h1
	# [4] text after the h1 (mixed content) ex: "Credits: 2"
	# 
	
	# <strong>Corequisite(s):</strong>
	# CS 112.
	# <br>
	# ---
	# title in <strong> tags
	# content
	# <br>
	
	# NOTE: regaurdless of the number of "lines", BS4 should parse all of the plain text in between the <strong></strong> and <br/> as one line. No need to check for the possibilty of mulitple lines.
	
	
	
	
	# figure out where the interesting section is
	start_i = 0
	end_i   = -1
	for i, token in enumerate(chunk.contents):
		if token.name == "h1":
			start_i = i
		if token.name == "div" and token["style"] == "float: right":
			end_i = i
			break
	
	
	
	# step through the interesting section, and extract valuable information
	target_indecies = set()
	dictionary = {}
	
	key   = None
	value = None
	
	segment = chunk.contents[start_i:end_i]
	
	
	dictionary["Title"]      = segment[0].contents[0].strip() # <h1>
	dictionary["Credits"]    = segment[1].strip()
	dictionary["Attempts"]   = segment[3].strip()
	dictionary["Department"] = segment[6].contents[0].strip() # <a>, href dept. page in the catalog
	
	
	# for description, start after the <hr> following an invisible <span></span>
	# and go until first <strong>
	# (this part may include mulitple lines, separated by <br/> tags)
	
	# itertools.takewhile explained here
	# src: http://stackoverflow.com/questions/9572833/break-list-comprehension
	
	# consume until contition to generate list
	description = list(itertools.takewhile(
	                lambda token: token.name != "strong", segment[11:len(segment)])
	              )
	# select only elements that are strings
	description = [x for x in description if isinstance(x, bs4.element.NavigableString)]
	# join, and then strip surrounding whitespace (keep internal spacing)
	description = "".join(description).strip()
	
	dictionary["Description"] = description
	
	for i, token in enumerate(segment):
		# print "%d >> %s" % (i, token)
		# NOTE: at this point, each token should be either a tag, blank line, or plain text
		
		# print type(token)
		
		# NOTE: this is how you check types in python
		# 	token is bs4.element.NavigableString   # exactly this class
		# 	isinstance(token, bs4.element.Tag)     # any descendent class
		if isinstance(token, bs4.element.Tag):
			if token.name == "strong":
				target_indecies.add(i)
				
				key = token.contents[0].strip().rstrip(':')
				# yield key
		elif isinstance(token, bs4.element.NavigableString):
			if (i-1) in target_indecies:
				value = token.strip()
				# yield value
		else:
			print "uhhh what? something has gone wrong"
		
		if key and value:
			# print "%s => %s" % (key, value)
			dictionary[key] = value
			key = None
			value = None
		
	# print dictionary
	print_dictionary(dictionary)
	# NOTE: remember that all fields in this dictionary are unicode strings, even the numbers.
	# TODO: consider converting the numerical fields to actual numbers
	
	# TODO: consider using "yield" instead of returning a Dictionary for more flexibility


# get a list of classes using the catalog search
# ex) "BIOL", "CS", etc
def search_by_department(dept_code):
	# use this url to search for courses
	# may return mulitple pages of results, but should be pretty clear
	url = "http://catalog.gmu.edu/content.php?filter%5B27%5D=" + dept_code + "&filter%5B29%5D=&filter%5Bcourse_type%5D=-1&filter%5Bkeyword%5D=&filter%5B32%5D=1&filter%5Bcpage%5D=1&cur_cat_oid=29&expand=&navoid=6272&search_database=Filter#acalog_template_course_filter"
	soup = get_soup(url)
	print "searching for classes under: " + dept_code
	# print url
	
	tag = soup.select("td.block_content_outer table")[3]
	write_html_to_file("./tmp/search.html", tag)
	
	tr_list = tag.select("tr")[2:-1]
	# write_html_to_file("./tmp/search_row.html", tag_list)
	
	
	
	tr_list = list(itertools.takewhile(
	                lambda tr: isinstance(tr.a, bs4.element.Tag), tr_list)
	              )
	course_listing = [extract_link(tr.a) for tr in tr_list]
	
	
	# TODO: make more robust by pulling from all pages in search, instead of just the first
	# TODO: allow filtering of results to limit to specific course number range (ie, you only want the undegrad courses)
	
	return course_listing
