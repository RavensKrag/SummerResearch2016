module SummerResearch


class CourseInfo
	attr_reader :url, :catalog_year, :id, :title, :credits, :attempts, :department
	
	def initialize(dept, course_number, catalog_year, url)
		@storage = nil
		
		
		@catalog_year = catalog_year
		@url          = url
		
		@id           = dept + ' ' + course_number
	end
	
	def ==(other)
		return false unless other.is_a? self.class
		
		@catalog_year == other.catalog_year and @id == other.id
	end
	
	
	
	# TODO: implement deserialization from MongoDB
	# TODO: maybe implement serialization *to* Mongo in this class as well? just pass in the Mongo object and do things that way?
	
	def to_h
		attributes = [:url, :catalog_year, :id, :title, :credits, :attempts, :department]
		
		values = 
			attributes.collect do |x|
				instance_variable_get("@#{x}")
			end
		
		attribute_strings = attributes.collect{  |x| x.to_s }
		attribute_strings.collect!{  |x| x == "id" ? "course_id" : x  }
		
		return attribute_strings.zip(values).to_h.merge(@storage)
	end
	
	
	# dump to the disk
	def dump
		
	end
	
	class << self
		# values set on init
		INITIAL_ATTRIBUTES = [:catalog_year, :url, :id].collect{|x| x.to_s }
		
		# values set in #fetch
		LATTER_ATTRIBUTES  = [:title, :credits, :attempts, :department].collect{|x| x.to_s }
		
		
		# load from object with hash-style interface
		# (actually expects a BSON::Document)
		def load(data)
			dept, course_number = parse_course_id(data['course_id'])
			catalog_year        = data['catalog_year']
			url                 = data['url']
			
			
			obj = self.new(dept, course_number, catalog_year, url)
			
			obj.instance_eval do
				# set instance variables not specified by the constructor
				LATTER_ATTRIBUTES.each do |attribute|
					instance_variable_set "@#{attribute}", data[attribute]
				end
				
				
				
				# restore the storage hash
				@storage = Hash.new
				
				keys = (data.keys - (INITIAL_ATTRIBUTES + LATTER_ATTRIBUTES))
				       .to_set
				
				keys.delete "_id"       # MongoDB key
				keys.delete "course_id" # represents @id in mongo ('id' and '_id' too similar)
				
				
				data.each do |k, v|
					if keys.include? k
						@storage[k] = v
					end
				end
			end
			
			return obj
			# ---
		end
		
		
		
		# 'parse_course_id()' copied from catlog.rb in 'catalog_scraper' package
		# this removed dependency on Catalog, which means you don't have to load ActiveRecord
		# for the web app
		
		# TODO: consider case of Mason Core classes
		def parse_course_id(course_id)
			dept_code     = nil
			course_number = nil
			
			if course_id.include? "Mason Core"
				dept_code = "Mason Core"
				
				matchdata = course_id.match(/Mason Core (.*)/)
				
				course_number = 
					if matchdata
						matchdata[1]
					else
						nil
					end
				
				# don't want it to trip up on just getting "Mason Core"
				# but not sure what to do, because this isn't really course?
			else
				dept_code, course_number = course_id.split(' ')
				course_number = course_number
			end
			
			return dept_code, course_number
		end
	end
	
	def [](key)
		if @storage.nil?
			raise "ERROR: No data yet. Remember to run #fetch on #{self.class} objects to pull down data from the catalog, before trying to read data."
		end
		
		return @storage[key]
	end
	
	
	
	
	
	
	
	# get from the online Catalog
	# NEW methodology: remove footer
	#                  flatten out the remaining <p> tags.
	#                  parse header, top, bottom (key => value section), 
	#                  and then whatever is left is the middle (description)
	# should work for everything, except for Mason Core
	def fetch
		# <strong>Prerequisite(s):</strong>
		# also corequites, etc
		# if mentions of prerequisites come up later, they will not be marked with <strong>
		# NOTE: much like how the general program page indents things, but they are not considered under a branch in the markup (just div with styling), <strong> creates visual separation without actual nesting in the DOM. May want to run similar preprocessing on these two segments.
		# NOTE: notes section usually explains extra requirements (take in x semester, take before x point in time, restricted to these people)
		# NOTE: PSYC 300 / 301 noted in program overview, supposed to be taken before Junior year, but that is NOT noted on the course themselves. Thus, if there is special info on the course page, it will be under NOTES, but it is not necessarily true that all course info will be in one place.
		# NOTE: some classes note in which semesters they are offered
		#       (ex STAT 344 says "When Offered: Fall, Spring, Summer")
		
		
		
		# GET THE DATA USING NOKOGIRI
		xml = Nokogiri::HTML(open(@url))
		chunk = xml.css('td.block_content_popup')
			# SummerResearch::Utilities.write_to_file("./course.html", chunk)
		
		
		# === figure out where the interesting section is, and store in 'segment' variable
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
		
		
		segment = list[(i_start..i_end)]
		
		
		
		
		
		# ---
		foo = ->(segment){
			signature_list = segment.collect{|x| x.name }
			signature = signature_list.join(' ')
			
			return signature_list, signature
		}
		
		segment = segment.to_a # needs to be a normal array, so you can use #pop(n)
		
		
		# --- remove the footer
			signature_list, signature = foo[segment]
				
			ending_string = "p text p text br br hr text div"
			ending_sequence = ending_string.split(' ')
			
			unless signature_list.last(ending_sequence.length) == ending_sequence
				raise "Does not match with expected ending seqence"
			end
			
			
			segment.pop(ending_sequence.length)
			
			signature_list, signature = foo[segment]
			
			p signature
		
		
		# --- flatten out remaning <p> elements
			segment.collect! do |node|
				if node.name == "p"
					node.enum_for(:traverse).to_a
				else
					node
				end
			end
			
			segment.flatten! # remove nested-structure as a result of previous #collect!
			
			
			
			signature_list, signature = foo[segment]
			
			p signature
		
		
		# -- parse heading
			h1_node = segment[0]
			@title = h1_node.inner_text.strip # <h1>
			
			@title = @title.split(' - ').last
		
		# --- Parse top section
			# # NOTE: should parses the top regaurdless of specific formatting, assuming all elements are at the same level of the tree.
			
			
			# index of the <hr> tag
			# (should only be one now, because the footer was removed)
			hr_i = signature_list.find_index("hr") || -1
			p hr_i
			
			top_segment = segment[1..hr_i]
			
			top_segment.tap do |segment|
				# p segment
				segment = segment.reject{  |tag| tag.inner_text.empty?  }
				                 .reject{  |tag| tag.inner_text == '&nbsp;'  }
				
				
				# puts "parts: #{segment.size}"
				# p segment.collect{|x| x.name }
				
				
				
				# p segment
				data = segment[0..1].collect{  |x| x.inner_text  }
				data[2] = segment[2..-1].collect{  |x| x.inner_text  }.reduce(&:+)
				
				
				
				
				@credits    = data[0].split(':').last.strip
				@attempts   = data[1].strip
				@department = if data[2].nil?
				              	''
				              else
				              	data[2].tr(' ', ' ').strip  
				              end
				# the first character here is not a normal space. the second one is normal.
				# it's not a tab either
				
				# (sometimes the department has a weird whitespace character at the end.)
				# (take that off)
				
				p [@credits, @attempts, @department]
			
			end
			
		
		# --- Parse bottom section
			# NOTE: at this point, each token should be either a tag, blank line, or plain text
			# want to look for properties in the following form
			# BOLD TEXT: value
			# where the bold text is marked using <strong></strong>, and the corresponding value is the next text token after that tag (think "mixed content")
			
			# --- Find where the <strong> tags are,
			#     and then grab the tags, and the text that comes after each tag,
			#     and zip them up into a Hash.
			puts "bottom section"
			# p segment
			
			segment = segment[hr_i..-1]
			signature_list, signature = foo[segment]
			
			p signature
			# p segment
			
			hr_i = 0 # redefininig this variable, because you have truncated the 'segment' list
			
			
			
			
			strong_tags_i_list = segment.each_index.select{  |i| segment[i].name == "strong"   }
			
			bottom_start_i = strong_tags_i_list.first
			
			
			
			# key   --- stuff in the <strong> </strong>
			# value --- anything after that, before the next <strong>
			out = Hash.new
			
			key = nil
			value_bucket = nil
			
			segment[bottom_start_i..-1].each do |node|
				if node.name == 'strong'
					# --- dump the old sequence, and start building up a new one
					# dump
					unless key.nil?
						out[key] = value_bucket.collect{  |x| x.inner_text  }.join("\n").strip
					end
					
					
					# NOTE: #tr is for character replacement, #gsub is for regex-based substring replacement
					
					# restart
					key = node.inner_text.tr(':', '')
					value_bucket = Array.new
				else
					value_bucket << node
				end
			end
			
			
			# # --- merge with other attributes from the header
			# out = out.merge attributes
			
			
			# --- Type conversion for integer fields
			out.keys.each do |key|
				if key.include? "Hours of" or key == "Credits"
					out[key] = out[key].to_i 
				end
			end
			
			
		
		# --- Whatever is left is the middle section
			p [hr_i..bottom_start_i]
			segment[hr_i..bottom_start_i].tap do |segment|
				# NOTE: Assuming that the entire body is flat. The <hr> lies at the same level of the HTML tree as the bolded elements indicated by <strong></strong>
					# At least in the case of EVPP 110, this is not the case. Other cases that break the "pattern" may also exist.
				
				
				# for description, start after the <hr> following an invisible <span></span>
				# and go until first <strong>
				# (this part may include mulitple lines, separated by <br/> tags)
				i_a = 0
				i_b = segment.find_index{  |x| x.name == "strong" } # stop when you find bold. before end.
				i_b ||= segment.size # walk from beginning to end
				
				
				
				
				# if there is a bolded KEY: value pair section
				description_sector = segment[i_a..(i_b-1)]
				attribute_sector   = segment[i_b..-1]
				
				# if there is not
				description_sector = segment[i_a..-1] # aka, the entire segment array
				
				
				
				
				
				out["Description"] =  
					segment[i_a..(i_b-1)].select{   |x| x.is_a? Nokogiri::XML::Text }
					                     .collect{  |x| x.inner_text }
					                     .join("\n\n")
			end
			
			
			
			@storage = out
		
		
		
		
		
		
		
		
		# --- output what you have found
		
		puts "------------------------"
		
		p chunk.children.collect{|x| x.name}[3..-1].join(' ')
		
		
		# TODO: remove 'type' from attributes. Don't care about that value any more.
		# (not just this list, but remove from all the code)
		[:url, :catalog_year, :id, :title, :credits, :attempts, :department].each do |attr|
			var = self.instance_variable_get("@#{attr}")
			p var
		end
		
		p @storage
		
		
		puts "===================================="
		
		# ---
		
		# unless success_flag
		# 	puts "=== Data dump"
		# 	p @catalog_year
		# 	p @id
		# 	# p @title # NOTE: you can't always get the title, because that needs to be parsed
		# 	p @url
		# 	p chunk.children.collect{|x| x.name}[3..-1].join(' ')
		# 	puts "====="
		# 	raise "ERROR: Course info page in an unexpected format. See data dump above, or stack trace below. Use CourseInfoDiagnostic.debug() / debug_verbose() for detailed analysis."
		# else
		# 	if @storage.nil?
		# 		# TODO: need a new way to check that the proper data is coming out of the callback
		# 		# this check no longer applies, and never truely secured against the error is was designed to protect against
		# 			# want to guard against not returning useful data out of the callback block.
		# 			# but 'useful data' is rather hard to define...
				
		# 		# ERROR: variable never set
		# 		raise "ERROR: variable @storage never set in course_info.rb.\n" +
		# 		      "(remember to set this variable in the type callback)"
		# 	elsif @storage.empty?
		# 		# WARNING: no data was found in the catalog for @id
		# 		warn "Warning: No data found in the catalog for course #{@id}"
		# 	end
		# end
		
		return self
	end
	
	
	# NOTE: this method is for testing only.
	# * Copy over code from #fetch 
	# * move code to output full page type signature BEFORE running type search
	# * replace #signature_match? wih #test_signature_match?
	# * replace #callback() with #test_callback()
	def test_types
		# GET THE DATA USING NOKOGIRI
		xml = Nokogiri::HTML(open(@url))
		chunk = xml.css('td.block_content_popup')
			# SummerResearch::Utilities.write_to_file("./course.html", chunk)
		
		
		# === figure out where the interesting section is, and store in 'segment' variable
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
		
		
		segment = list[(i_start..i_end)]
		
		
		
		p @catalog_year
		p @id
		# p @title # NOTE: you can't always get the title, because that needs to be parsed
		p @url
		p chunk.children.collect{|x| x.name}[3..-1].join(' ')
		# p segment.collect{|x| x.name}.join(' ') # is this the same signature? nope...
		
		
		
		
		
		type_search_order = TYPE_SEARCH_ORDER
		
		# ---
		success_flag = 
			type_search_order.any? do |type_class|
				type = type_class.new(self)
				
				if type.test_signature_match?(segment)
					# when a matching signature is found,
					# run the callback, and then do not look for any other potential callbacks
					@storage = type.callback(segment)
					@type    = type.class.to_s.split('::').last
					puts "=> #{@type}"
					
					# pseudo-return for the block
					true
				end
			end
		# ---
		
		unless success_flag
			raise "ERROR: Course info page in an unexpected format. See data dump above, or stack trace below. Use CourseInfoDiagnostic.debug() / debug_verbose() for detailed analysis."
		end
		
		
		
		
		# This method must always raise an error, because it is being called from
		# foo14, which uses the structure of foo11,
		# which only prints debug info when errors are thrown
		# (Really want to maintain similarity betwen foo14 and foo11.)
		# (Will certainly make code easier to maintain in the long-run)
		raise
	end
	
	
	
	
	
	# === Classify Type of Course Info Page
	# === Based on the type, perform different parsing
	# 
	# Based on the names of tags the Aray 'segment',
	# various different types of course info pages can be identified
	# 
	# Each type signature is associated with a different callback for parsing that page layout.
	# (some minor code duplication, but this structure is very flexible.)
	
	
	# initialization doesn't really do anything right now,
	# but using class methods may have weird side effects when combined with inheritance,
	# so just leave it like this.
	
	
	
	
	# Think of the pages as having 4 sectors:
	# 
	# * heading --- course name - description
	# * top     --- credits, repetition, department
	# * middle  --- long description
	# * bottom  --- various tags: prereqs, coreqs
	# 
	# 
	# these sections may or may not be wrapped in containers
	# 
	# (headers as of now are always raw, 'n' => no container / 'y' => wrapped in container)
	#           top, mid, bot
	# A: heading, n,  n,  n
	# B: heading, n,  y,  y        technically, B just cuts the middle in half, b/c it's v. weird
	# C: heading, n,  n,  y
	# 
	# (This is not a rigourous enough definiton to actually separate the types, especially in the case of Type B, but this helps to understand generally what is going on. Take a look at some examples of all the types to further undertand. Examples can be found in the CourseInfo diagnostic in the project Rakefile)
	
	
	# NOTE: these type classes are depreciated.
	# need to completely remove all code that uses this stuff.
	# I think that mainly means the debug diagnostics?
	# How can those be updated? Scrap them?
	
	
	class BaseType
		def initialize(course_info_object)
			@context = course_info_object
		end
		
		def signature_match?(node_list)
			type_signature = self.class.const_get "SIGNATURE"
			
			# NOTE: Enumerable#all? will short-circuit
			flag = node_list.first(type_signature.size).collect{  |x| x.name  }
			            .zip(type_signature)
			            .all? do |child_name, token_type|
			            	child_name == token_type
			            end
			
			return flag
		end
		
		# Should be exactly the same as #test_signature, but with debug printing enabled
		# Should be used for testing purposes only
		# * print lines before and after the block
		# * inside the block, print out each pair [found node, expected type]
		def test_signature_match?(node_list)
			type_signature = self.class.const_get "SIGNATURE"
			
			puts "----"
			flag = node_list.first(type_signature.size).collect{  |x| x.name  }
			            .zip(type_signature)
			            .all? do |child_name, token_type|
			            	p [child_name, token_type]
			            	child_name == token_type
			            end
			puts "----"
			
			return flag
		end
		
		# def test_callback(segment)
		# 	puts "=> #{self.class.name}"
		# end
		
		def callback(segment)
			raise "ERROR: #{self.class.name}#callback() needs to be defined with custom behavior."
		end
		
		
		
		# Mostly, this private section exists to share code between different types.
		# This should probably actually be a module or something, because it
		# doesn't make sense for the interitance heiarchy to but this code here.
		private
		
		# TODO: should probably do away with using instance_eval to set values like this. The interface for CourseInfo should probably become more uniformly hash-like as well, instead of using some hash access, and object-like access for the properties that "always exist".
		def parse_heading(h1_node)
			@context.instance_eval do
				@title = h1_node.inner_text.strip # <h1>
				
				@title = @title.split(' - ').last
			end
		end
		
		def parse_top_chunk(segment)
			# NOTE: should parses the top regaurdless of specific formatting, assuming all elements are at the same level of the tree.
			@context.instance_eval do
				segment = segment.select{  |tag| tag.respond_to? :inner_text  }
				                 .reject{  |tag| tag.inner_text.empty?  }
				                 .reject{  |tag| tag.inner_text == '&nbsp;'  }
				
				
				# puts "parts: #{segment.size}"
				# p segment.collect{|x| x.name }
				
				
				data = segment[0..2].collect{  |x| x.inner_text  }
				if segment.last.name == 'a'
					# if the last item is a link, fuse it with the second-to-last thing
					# <a>, href dept. page in the catalog
					data[2] += segment[3].inner_text
				end
				
				
				
				@credits    = data[0].split(':').last.strip
				@attempts   = data[1].strip
				@department = data[2].tr(' ', ' ').strip
				# the first character here is not a normal space. the second one is normal.
				# it's not a tab either
				
				# (sometimes the department has a weird whitespace character at the end.)
				# (take that off)
				
				p [@credits, @attempts, @department]
			end
		end
		
		def parse_body(segment)
			out = Hash.new
			
			
			# NOTE: Assuming that the entire body is flat. The <hr> lies at the same level of the HTML tree as the bolded elements indicated by <strong></strong>
				# At least in the case of EVPP 110, this is not the case. Other cases that break the "pattern" may also exist.
			
			
			# for description, start after the <hr> following an invisible <span></span>
			# and go until first <strong>
			# (this part may include mulitple lines, separated by <br/> tags)
			i_a = 0
			i_b = segment.find_index{  |x| x.name == "strong" } # stop when you find bold. before end.
			i_b ||= segment.size # walk from beginning to end
			
			
			
			
			# if there is a bolded KEY: value pair section
			description_sector = segment[i_a..(i_b-1)]
			attribute_sector   = segment[i_b..(segment.size-1)]
			
			# if there is not
			description_sector = segment[i_a..(segment.size-1)] # aka, the entire segment array
			
			
			
			
			
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
	end
	
	class TypeA < BaseType
		SIGNATURE = %w[h1 text br text br text a span text hr]
		
		def callback(segment)
			# puts "TYPE A"
			# table      <-- skip this
			# h1         <-- name of course again
			# * data you actually care about
			# * (some formatting markup, no semantic tree-like structure)
			# *
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
			
			
			
			heading = segment[0]
			top     = segment[1..6]
			rest    = segment[7..-1]
			
			# TODO: consider that some code from #parse_body may need to move into this section
			# parse_body() should only contain "universal" code
			
			
			# Unified processing, regaurdless of where the pieces are located
			parse_heading(heading)
			parse_top_chunk(top)
			body_data    = parse_body(rest)
			
			# p [heading_data.class, top_data.class, body_data.class]
			
			return body_data
		end
	end
	
	class TypeB < BaseType
		SIGNATURE = %w[h1 p hr text p   p p text p]
		
		def callback(segment)
			# puts "TYPE B"
			# first string in that last string of 4 is the one you want
			
			# p segment.collect{|x| x.name }.join(' ')
			# => "h1 p hr text p p p text p text br br hr text div"
			#     0  1 2  3    4 5 6 7    8 9    10 11 12 13   14 
			
			heading = segment[0]
			top     = segment[1].children
			rest    = segment[4].children
			
			# SummerResearch::Utilities.write_to_file("./course_info_type_b", rest)
			
			
			# Unified processing, regaurdless of where the pieces are located
			parse_heading(heading)
			parse_top_chunk(top)
			body_data    = parse_body(rest)
			
			# p [heading_data.class, top_data.class, body_data.class]
			
			return body_data
		end
	end
	
	class TypeC < BaseType
		SIGNATURE = %w[h1 text br a]
		
		def callback(segment)
			# puts "TYPE C"
			# Mason Core listing actually uses Type A format,
			# but it doesn't list even a single "KEY: value" pair,
			# and then absense of the bold items alone is what throws off the parsing
			
			# may want to still declare this as a third Type C format?
			# It is rather different, because the Mason Core course entries are not really courses
			# they are just aliases for whole lists of courses
			
			
			# Actually wait no, it's actually pretty different, because the total absense of an <hr> to show where the top sector ends
			
			heading = segment[0]
			parse_heading(heading)
			
			
			other_data = Hash.new
			other_data["Credits"]     = segment[1].inner_text.split(':').last.strip
			other_data["Course List"] = segment[3]['href']
			
			
			return other_data
		end
	end
	
	
	
	class TypeD < BaseType # Similar to Type A (no link to department)
		SIGNATURE = %w[h1 text br text br text hr]
		
		def callback(segment)
			heading = segment[0]
			top     = segment[1..6]
			rest    = segment[7..-1]
			
			# TODO: consider that some code from #parse_body may need to move into this section
			# parse_body() should only contain "universal" code
			
			
			# Unified processing, regaurdless of where the pieces are located
			parse_heading(heading)
			parse_top_chunk(top)
			body_data    = parse_body(rest)
			
			# p [heading_data.class, top_data.class, body_data.class]
			
			return body_data
		end
	end
	
	class TypeE < BaseType # Similar to Type A, very similar to Type D
		SIGNATURE = %w[h1 text br text br text a span hr]
		
		def callback(segment)
			heading = segment[0]
			top     = segment[1..6]
			rest    = segment[7..-1]
			
			# TODO: consider that some code from #parse_body may need to move into this section
			# parse_body() should only contain "universal" code
			
			
			# Unified processing, regaurdless of where the pieces are located
			parse_heading(heading)
			parse_top_chunk(top)
			body_data    = parse_body(rest)
			
			# p [heading_data.class, top_data.class, body_data.class]
			
			return body_data
		end
	end
	
	
	# Ordered list of types to check for.
	# Will attempt to match types higher up on the list, before types lower in the list
	
	# NOTE: *** Reorder this list to change search priority ***
	TYPE_SEARCH_ORDER = [
		TypeA,
		TypeB,
		TypeC,
		TypeD,
		TypeE
	]
	
	
	
	# === Format of interesting sector Type A
	# h1
	# <p> header data block </p>
	# <hr>
	# description block
	# (NOTE: no <p> here AT ALL)
	# notes
	# <strong>Key:</strong>
	# Value
	# <br> (may be multiple of these)
	# <img> (various badges, like NEW COURSE, or SUSTAINABLE MASON)
	# <p></p> (spacer)
	# <p>Schedule for THIS semster</p> (this two links include the Summer as a semester)
	# <p>Schedule for NEXT semster</p> (ie, "Summer / Fall", or "Fall / Spring")
	# (other tags... A and B are slightly different)
	# ===============
	
	# pretty much the same, except B has one section "indented"
	# and Type A doesn't have the <p> after the description block
	
	# === Format of interesting sector Type B
	# h1 (Course ID and Name)
	# <p> header data block
		# credits
		# attempts
		# offered by
	# </p>
	# <hr>
	# description block
	# <p></p> (yes, there is a blank <p> AFTER the description, rather than AROUND it)
	# <p>
		# notes
		# <strong>Key:</strong>
		# Value
		# <br> (may be multiple of these)
		# <img> (various badges, like NEW COURSE, or SUSTAINABLE MASON)
	# </p>
	# <p></p> (spacer)
	# <p>Schedule for THIS semster</p> (this two links include the Summer as a semester)
	# <p>Schedule for NEXT semster</p> (ie, "Summer / Fall", or "Fall / Spring")
	# ===============
end



end
