# use 'pip' for package management
# (very similar to 'gem' in Ruby)

import requests
from bs4 import BeautifulSoup


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

def get_soup(url):
	r = requests.get(url)

	content = r.content

	soup = BeautifulSoup(content, "html.parser")
	
	return soup

def find_possible_degrees(url):
	soup = get_soup(url)

def degree_requirements(url):
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
	# Psych BA    "Degree Total: Minimum 120 credits" 
	
	
	
	
	
	# TODO: raise exception if a != 0
		# I assume that it should always be 0, so
		# if that fundamental underlying assumption is broken,
		# it is possible that many things have actually broken.
	
	# TODO: raise exception if a == -1 OR b == -1
		# this means that the values were never initialized
		# you need BOTH to be set
	
	# TODO: figure a better way of getting the start and end points, a and b
	
	
	
	x = list(requirements.children)[a]
	
	text = x.get_text()
	print text
	
	x = list(requirements.children)[b]
	
	
	text = x.get_text()
	print text

	
	
	
	# ruby: arry[0..3]  # inclusive of both ends
	# python: arry[0:4] # exclusive of the top end
	x = list(requirements.children)[(a+1):b]
	# ok, this is the level where the stuff is
	print type(x)
	
	write_html_to_file("fragment.html", x)
	
	
	
	
	
	# notes on BeautifulSoup4:
	# .contents returns a list
	# .children returns interator (same content)
	# .descendants is a full tree traversal
	
	
	
	# outer div with a bunch of divs inside it
		# heading
		# actual list of requiremnts (divided into many sub-sections)
		# total number of credits
		# honors program
		# change of major
		# etc
		
		
	# when examining the CS requriments: (seems to work for both CS and ACS)
	# list(requirements.children)[0] # header
	# list(requirements.children)[1] # main requirements
	#                                # (many divs inside here that break doc into sections)
	# list(requirements.children)[2] # total number of credits
	
	# list(requirements.children)[3] # each div from here on out has an h2 element with a title,
	#                                #  and some text
	
	
	
	# in the main div list:
		# .acalog-core is the main stuff
		# the other ones with inline style "padding-left: 20px" are notes etc
		# (they aren't structurally under their "parent" elements, but visually and conceptually there is a clear parent-child relationship)
		
	
	
	
	# ok, to list this in a more robust way:
	# h2: "Degree Requirements"
	# * 
	# * one or more divs and their subcontainers that list course requirements
	# * (probably want to keep this tree-like structure)
	# * 
	# h2: line listing the total number of credits (CS says "Total: " Bio BA says "Degree Total: ")
	# * zero or more extra sections listing additional notes etc
	
	
	
	
	
	
	# ohhh this is weird
	# this document has many anchor tags <a>
	# that are not actually hyperlinks.
	# They are there so that you could add #foo at the end of the URL to jump to anchor "foo"




# main
# url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28260&returnto=6270" # CS BS
url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28210&returnto=6270" # biol BA
# url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28492&returnto=6270" # Psych BA
degree_requirements(url)




# parse programs of study page to get programs
# parse each of those to get the courses
# output course information and dependencies

# another pass to figure out the program requirements?
# higher-level dependecies than just what course requires what.
# Need to understand that you need a certain number of courses from particular categories.
