module SummerResearch

	CatalogLink = Struct.new("CatalogLink", :id, :description, :url)

	class << self


def degree_requirements(url)
	fragment = requirements_subtree(url)
	
	out = 
	fragment.collect do |node|
		# puts node.class
		# onclick_scripts = node.xpath('.//a[@onclick]').collect{  |link| link['onclick']  }
		# onclick_scripts.each do |script|
		# end
		
		get_all_weird_link_urls(node)
	end
	
	return out.flatten
end

def requirements_subtree(url)
	xml = Nokogiri::HTML(open(url))
	
	top        = xml.css('table.block_n2_and_content')
	main_table = top.css('td.block_content_outer')
		Utilities.write_to_file("./ruby_test.html", main_table)
	
	
	
	
	title       = main_table.css('h1#acalog-content').inner_html
	banner_code = main_table.css('td.block_content p')[1].css('strong').inner_html

		h2 = main_table.css('td.block_content p')[2]
		links = h2.css('a')
		links[1]
	
	school      = links[0]
	department  = links[1]
	description = h2
	
	# WARNING: mixed content. No good way to just grab the description.
		# Degree name
		# banner code
		# school
		# department
		# description
	# are all at the same level of the tree.
	
	description_container = main_table.css('td.block_content > table tr')[0]
		# contains sections described in comment above
	
	
	requirements = main_table.css('td.block_content > table tr > td')[3]
		# should contain the actual course info
		Utilities.write_to_file("./requirements.html", requirements.inner_html)
		
		# outer div with a bunch of divs inside it
			# requirements
			# total number of credits
			# honors program
			# change of major
			# etc
	
	
	# when examining the CS requriments: (seems to work for both CS and ACS)
	# a.children[0] # header
	# a.children[1] # main requirements (many divs inside here that break doc into sections)
	# a.children[2] # total number of credits
	
	# a.children[3] # each div from here on out has an h2 element with a title, and some text
	
	
	# in the main div list:
		# .acalog-core is the main stuff
		# the other ones with inline style "padding-left: 20px" are notes etc
	
	
	
	# ok, to list this in a more robust way:
	# h2: "Degree Requirements"
	# * 
	# * one or more divs and their subcontainers that list course requirements
	# * (probably want to keep this tree-like structure)
	# * 
	# h2: line listing the total number of credits (CS says "Total: " Bio BA says "Degree Total: ")
	# * zero or more extra sections listing additional notes etc
	
	
	
	
	# === get the section between the header and the number of credits
	
	# requirements.css('div').size
	# puts requirements.children.size
	
	# requirements.children => [some whitespace at top of file, outer div]
	# css: outer div > actual content
	list = requirements.children[1].children
	# puts list.size
	
	# list.each_with_index do |node, i|
	# 	puts node.class
		
	# 	if node.inner_text.include? "Degree Requirements"
	# 		puts "start: #{i}"
	# 	elsif node.inner_text.include? "Total:"
	# 		puts "end: #{i}"
	# 	end
	# end
	
	i_start = list.find_index{  |x| x.inner_text.include? "Degree Requirements" }
	i_end   = list.find_index{  |x| x.inner_text.include? "Total:" }
	
	
	fragment = list[i_start..i_end]
		Utilities.write_to_file("./fragment.html", fragment)
	
	return fragment
	
	
	# different end markers for different departments
	# (note that Psych BA uses "Total: " to show subtotals)
	# Really want to check for the substrings "Total:" and "120 credits"
	
	# program     target end string                     range
	# -------     -------------------                   ------
	# CS BS       "Total: 120 credits"                  (0..2)
	# Bio BA      "Degree Total: Minimum 120 credits"   (0..5)
	# Psych BA    "Degree Total: Minimum 120 credits"   (?..?)
	
	# NOTE: section headings for "Mason Core" and "BA Requirements" may vary
end



def get_all_weird_link_urls(node)
	# ------
	node.xpath('.//a[@onclick]')
	    .collect{  |link_node|  unpack_catalog_link(link_node)  }
	# ------
end

def unpack_catalog_link(node)
	text = node.inner_text
	text.gsub!(" - ", " - ") # replace em-dash (long one) with en-dash (ASCII)
	
	id, description = text.split(" - ")
	
	url = extract_link(node['onclick'])
	
	
	return CatalogLink.new(id, description, url)
end

def extract_link(script)
	regexp_a = /showCourse\('(.+?)'\, '(.+?)',this,/
	regexp_b = /acalogPopup\('(.+?)'.*/
	regexp_c = /showCatalogData\('(\d+?)'\, '(\d+?)'\, '(\d+?)'\, '(.+?)'/
	
	# TEST: checks to see that either one match or the other is found, but not both
	# puts script.scan(regexp_a).size + script.scan(regexp_b).size == 1
	
	
	# TODO: use #match not #scan. #scan gives all matches, and #match gives only one, and there should only ever be one
	# NOTE: you actually get a different type out, but the interface is exactly the same because of Ruby's ability to implement the array-style access
	
	# oh but wait, this block only gets evaluated if there is a match, so that's rather convienent
	a = 
		script.scan(regexp_a).collect do |a,b|
			"preview_course.php?catoid#{a}&coid=#{b}&print"
		end
	
	b = 
		script.scan(regexp_b).collect do |matches|
			matches.first
		end
	
	c = 
		script.scan(regexp_c).collect do |a,b,c,d|
			# p [a,b,c,d]
			"preview_course.php?catoid#{a}&coid=#{c}&print"
		end
	
	# two lists joined together, resulting list always has size of 1
	# as show in the the test near the top of this method.
	results = (a + b + c)
	unless results.size == 1
		raise "Error: could not find catalog course link inside this script.\n" +
		      "Script dump:\n" +
		      "===================\n" +
		      script + "\n" +
		      "===================\n"
	end
	
	local_link = results.first
	
	return "http://catalog.gmu.edu/" + local_link
end

def search_programs_of_study(url, target_fields)
	levels = %w[BS BA MS PhD MA]
	# TODO: limit degrees by education level
	
	
	# --- fetch the page from the internet
	# note: catoid encodes the catalog year
	xml = Nokogiri::HTML(open(url))
	
	puts "downloading list of all programs at Mason..."
	# --- grab unordered list from the HTML
	ul = xml.css('td.block_content_outer ul li')
	
	# --- get just the relevant string names, and the links to the requirements pages
	all_degrees = ul.collect do |x|
		# puts x.class
		# puts x.xpath('./a').first['href']
		# p x.inner_text # "• \nWomen and Gender Studies Minor"
		link = x.xpath('./a').first['href']
		text = x.inner_text[3..-1].strip # take the
		
			# benchmark of 'remove first few characters' approaches in Ruby
			# http://stackoverflow.com/questions/3614389/what-is-the-easiest-way-to-remove-the-first-character-from-a-string
		link = "http://catalog.gmu.edu/" + link
		
		[text, link]
	end
	
	puts "searching..."
	# --- convert associative array into a hash
	programs_of_study = all_degrees.to_h
	
	
	# --- select the degrees where one of the target fields is found as a substring
	selected_degrees = 
		programs_of_study.keys.select do |degree_name|
			# normalize
			x = degree_name.downcase
			y = target_fields.collect{|x| x.downcase }
			
			# perform actual selection
			if y.any?{  |q|  x.include? q    }
				true
			end
		end
	# puts selected_degrees
	
	
	# --- limit the outgoing hash to only the selected fields
	# (this way, you can use the size of the hash to see how many hits your query gets)
	programs_of_study.delete_if{  |key| not selected_degrees.include? key }
		# TODO: consider using a set to speed up #include?
	
	# puts "===================="
	
		
	return programs_of_study
end

# given catalog URL, extract information into a Hash
def course_info(url)
	# <strong>Prerequisite(s):</strong>
	# also corequites, etc
	# if mentions of prerequisites come up later, they will not be marked with <strong>
	# NOTE: much like how the general program page indents things, but they are not considered under a branch in the markup (just div with styling), <strong> creates visual separation without actual nesting in the DOM. May want to run similar preprocessing on these two segments.
	# NOTE: notes section usually explains extra requirements (take in x semester, take before x point in time, restricted to these people)
	# NOTE: PSYC 300 / 301 noted in program overview, supposed to be taken before Junior year, but that is NOT noted on the course themselves. Thus, if there is special info on the course page, it will be under NOTES, but it is not necessarily true that all course info will be in one place.
	# NOTE: some classes note in which semesters they are offered
	#       (ex STAT 344 says "When Offered: Fall, Spring, Summer")
	
	
	# GET THE DATA USING NOKOGIRI
	xml = Nokogiri::HTML(open(url))
	chunk = xml.css('td.block_content_popup')
		Utilities.write_to_file("./course.html", chunk)
	
	
	out = Hash.new
	
	
	
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
	list = chunk.children
	
	# puts list.size
	
	# list.each do |node|
	# 	puts node.class
	# 	if node.class == Nokogiri::XML::Element
	# 		# p node.name
	# 		# p node.methods
	# 		break
	# 	end
	# end
	
	i_start = list.find_index{  |x| x.name == "h1" }
	i_end   = list.find_index{  |x| x.name == "div" and x["style"] == "float: right" }
	
	
	
	
	# step through the interesting section, and extract valuable information
	
	# ===== parse the header
	segment = list[(i_start..i_end)]
	
	out["Title"]      = segment[0].inner_text.strip # <h1>
	out["Credits"]    = segment[1].inner_text.split(':').last.strip
	out["Attempts"]   = segment[3].inner_text.strip
	out["Department"] = segment[6].inner_text.strip # <a>, href dept. page in the catalog
	
	
	
	# ===== parse the body
	
	# NOTE: Assuming that the entire body is flat. The <hr> lies at the same level of the HTML tree as the bolded elements indicated by <strong></strong>
		# At least in the case of EVPP 110, this is not the case. Other cases that break the "pattern" may also exist.
	
	
	# for description, start after the <hr> following an invisible <span></span>
	# and go until first <strong>
	# (this part may include mulitple lines, separated by <br/> tags)
	i_a = segment.find_index{  |x| x.name == "hr" }
	i_b = segment.find_index{  |x| x.name == "strong" }
	
	
	out["Description"] =  
		segment[i_a..(i_b-1)].select{   |x| x.is_a? Nokogiri::XML::Text }
		                     .collect{  |x| x.inner_text }
		                     .join("\n\n")
	
	
	# NOTE: at this point, each token should be either a tag, blank line, or plain text
	# want to look for properties in the following form
	# BOLD TEXT: value
	# where the bold text is marked using <strong></strong>, and the corresponding value is the next text token after that tag (think "mixed content")
	
	# --- Find where the <strong> tags are,
	#     and then grab the tags, and the text that comes after each tag,
	#     and zip them up into a Hash.
	list = segment[i_b..-1]
	strong_tags_i = list.to_a.each_index.select{  |i| list[i].name == "strong"   }
	strong_tags   = strong_tags_i.collect{  |i| list[i].inner_text.strip    }
	value_strings = strong_tags_i.collect{  |i| list[i+1].inner_text.strip  }
	
	# NOTE: #tr is for character replacement, #gsub is for regex-based substring replacement
	strong_tags.collect!{  |x| x.tr(':', '')   }
	attributes = strong_tags.zip(value_strings).to_h
	
	# --- merge with other attributes from the header
	out = out.merge attributes
	
	
	# --- Type conversion for integer fields
	out.keys.each do |key|
		if key.include? "Hours of" or key == "Credits"
			out[key] = out[key].to_i 
		end
	end
	
	
	return out
end

# get a list of classes using the catalog search
# ex) "BIOL", "CS", etc
# returns a list of triples: dept_code, class_number, url
#                       ex) [CHEM, 313, catalog_URL_here]
def search_by_department(dept_code)
	# use this url to search for courses
	# may return mulitple pages of results, but should be pretty clear
	url = "http://catalog.gmu.edu/content.php?filter%5B27%5D=" + dept_code + "&filter%5B29%5D=&filter%5Bcourse_type%5D=-1&filter%5Bkeyword%5D=&filter%5B32%5D=1&filter%5Bcpage%5D=1&cur_cat_oid=29&expand=&navoid=6272&search_database=Filter#acalog_template_course_filter"
	
	xml = Nokogiri::HTML(open(url))
	
	puts "searching for classes under: " + dept_code + " ..."
	
	node = xml.css('td.block_content_outer table')[3]
		Utilities.write_to_file("./search.html", node)
	
	tr_list = node.css('tr')[2..-1]
	
	# tr_list.each{|x| puts x.class }
	return tr_list.collect{  |x| get_all_weird_link_urls(x)  }.flatten
end



end
end
