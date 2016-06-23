module SummerResearch
	
	PROGRAMS_OF_STUDY_URL  = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6270"
	COURSE_SEARCH_BASE_URL = "http://catalog.gmu.edu/content.php?catoid=29&navoid=6272"
	
	CatalogLink = Struct.new("CatalogLink", :id, :description, :url, :link_type)

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
	
	url, link_type = extract_link(node['onclick'])
	
	
	return CatalogLink.new(id, description, url, link_type)
end

def extract_link(script)
	# TEST: checks to see that either one match or the other is found, but not both
	# puts script.scan(regexp_a).size + script.scan(regexp_b).size == 1
		
	patterns = {
		"Type A" => {
			:pattern  => /showCourse\('(.+?)'\, '(.+?)',this,/,
			:callback => ->(matches){
				all, a,b = matches.to_a
				"preview_course.php?catoid=#{a}&coid=#{b}&print"
			}
		},
		
		"Type B" => {
			:pattern  => /acalogPopup\('(.+?)'.*/,
			:callback => ->(matches){
				matches[1]
			}
		},
		
		"Type C" => {
			:pattern  => /showCatalogData\('(\d+?)'\, '(\d+?)'\, '(\d+?)'\, '(.+?)'/,
			:callback => ->(matches){
				all, a,b,c,d = matches.to_a
				# p [a,b,c,d]
				"preview_course.php?catoid=#{a}&coid=#{c}&print"
			}
		}
	}
	
	name_url_pairs = 
		patterns.lazy
		        .collect{  |type, data|   [type, script.match(data[:pattern]), data[:callback]]  }
		        .reject{   |type, match, callback|  match.nil?  }
		        .collect{  |type, match, callback|  [type, callback[match]]  }
		        .to_a
	
	name_url_pairs.size == 1
	
	# TODO: remove '&print' from URLs, so if you every have to view the page manually for debugging etc, you get the nice looking UI, and not the print-friendly UI.
	# (I've been just removing that bit manually, but that seems a bit silly.)
	
	unless name_url_pairs.size == 1
		puts "==== Data Dump ===="
		puts "Script:"
		puts script
		puts "Regex Sets:"
		p name_url_pairs
		puts "==================="
		
		raise "Error: could not find catalog course link inside this script. See data dump above, or stack trace below."
	end
	
	# should only ever be one at this point
	type, local_link = name_url_pairs.first
	
	return "http://catalog.gmu.edu/" + local_link, type
end

def search_programs_of_study(target_fields)
	levels = %w[BS BA MS PhD MA]
	# TODO: limit degrees by education level
	
	
	# --- fetch the page from the internet
	# note: catoid encodes the catalog year
	xml = Nokogiri::HTML(open(PROGRAMS_OF_STUDY_URL))
	
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

# get a list of classes using the catalog search
# ex) "BIOL", "CS", etc
# returns a list of CatalogLink objects
def search_by_department(dept_code)
	# use this url to search for courses
	# may return mulitple pages of results, but should be pretty clear
	
	# TODO: modify url to use COURSE_SEARCH_BASE_URL constant (reorder url args)
	url = "http://catalog.gmu.edu/content.php?filter%5B27%5D=" + dept_code + "&filter%5B29%5D=&filter%5Bcourse_type%5D=-1&filter%5Bkeyword%5D=&filter%5B32%5D=1&filter%5Bcpage%5D=1&cur_cat_oid=29&expand=&navoid=6272&search_database=Filter#acalog_template_course_filter"
	
	xml = Nokogiri::HTML(open(url))
	
	puts "searching for classes under: " + dept_code + " ..."
	
	node = xml.css('td.block_content_outer table')[3]
		# Utilities.write_to_file("./search.html", node)
	
	tr_list = node.css('tr')[2..-1]
	
	# tr_list.each{|x| puts x.class }
	return tr_list.collect{  |x| get_all_weird_link_urls(x)  }.flatten
end


# find out where all the specific course data is located for every single course offered
# NOTE: search_by_department() only actually checks the first page of results, so this may not get EVERYTHING, but should be enough to analyse undergraduate requirements.
def foo5
	departments      = all_department_codes()
	courses_per_dept = departments.collect{  |dept|  SummerResearch.search_by_department(dept) }
										# (no specific data. just URLs, link types, etc)
	
	return departments.zip(courses_per_dept).to_h
end


def all_department_codes
	xml = Nokogiri::HTML(open(COURSE_SEARCH_BASE_URL))
	
	#course_search > table > tbody > tr:nth-child(4) > td:nth-child(1) > select
	segment = xml.css('#course_search table tr:nth-child(4) > td:nth-child(1) > select > option')
		# Utilities.write_to_file("./department_codes_fragment.html", segment)
	
	departments = segment.collect{  |option_node|  option_node["value"]  } 
	departments.shift # remove the first one, which is just -1, the default nonsense value
	
	return departments
end



end
end
