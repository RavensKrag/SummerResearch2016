module SummerResearch


class CourseInfo
	attr_reader :url, :id, :title, :credits, :attempts, :department, :catalog_version
	
	def initialize(course)
		@storage = nil
		
		@url = course.url
			regex = /catoid=(\d+)/
			@catalog_version = @url.scan(regex)
		@id  = course.id
	end
	
	def ==(other)
		return false unless other.is_a? self.class
		
		@catalog_version == other.catalog_version and @id == other.id
	end
	
	
	
	# get from the online Catalog
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
			Utilities.write_to_file("./course.html", chunk)
		
		
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
		
		
		# === Classify Type of Course Info Page
		# === Based on the type, perform different parsing
		# 
		# Based on the names of tags the Aray 'segment',
		# various different types of course info pages can be identified
		# 
		# Each type signature is associated with a different callback for parsing that page layout.
		# (some minor code duplication, but this structure is very flexible.)
		info_page_types = {
			:type_a => {
				:signature => %w[h1 text br text br text a span text hr],
				:callback  => ->(){
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
					
					@storage = body_data
				}
			},
			
			:type_b => {
				:signature => %w[h1 p hr text p   p p text p],
				:callback  => ->(){
					# puts "TYPE B"
					# first string in that last string of 4 is the one you want
					
					# p segment.collect{|x| x.name }.join(' ')
					# => "h1 p hr text p p p text p text br br hr text div"
					#     0  1 2  3    4 5 6 7    8 9    10 11 12 13   14 
					
					heading = segment[0]
					top     = segment[1].children
					rest    = segment[4].children
					
					# Utilities.write_to_file("./course_info_type_b", rest)
					
					
					# Unified processing, regaurdless of where the pieces are located
					parse_heading(heading)
					parse_top_chunk(top)
					body_data    = parse_body(rest)
					
					# p [heading_data.class, top_data.class, body_data.class]
					
					@storage = body_data
				}
			},
			
			:type_c => {
				:signature => %w[h1 text br a], # never any <hr> dividing the header from body,
				:callback  => ->(){
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
					
					
					@storage = other_data
				}
			}
		}
		# TODO: consider moving 'info_page_types' outside of this method, to dramatically reduce duplication between this method, and the testing variant, #test_types
			# (remember that this will alter how data is passed into those lambdas)
		
		
		
		# Ordered list of types to check for.
		# Will attempt to match types higher up on the list, before types lower in the list
		
		# NOTE: *** Reorder this list to change search priority ***
		type_search_order = [
			:type_a,
			:type_b,
			:type_c
		]
		# ---
		success_flag = 
			type_search_order.any? do |name|
				type = info_page_types[name]
				
				if signature_match?(segment, type[:signature])
					# when a matching signature is found,
					# run the callback, and then do not look for any other potential callbacks
					type[:callback].call()
					
					# pseudo-return for the block
					true
				end
			end
		# ---
		unless success_flag
			puts "=== Data dump"
			p chunk.children.collect{|x| x.name}[3..-1].join(' ')
			puts "====="
			raise "ERROR: Course info page in an unexpected format. See data dump above, or stack trace below. Use foo14 (pathway8) for detailed analysis."
		else
			if @storage.nil?
				# ERROR: variable never set
				raise "ERROR: variable @storage never set in course_info.rb.\n" +
				      "(remember to set this variable in the type callback)"
			elsif @storage.empty?
				# WARNING: no data was found in the catalog for @id
				warn "Warning: No data found in the catalog for course #{@id}"
			end
		end
		
		return self
	end
	
	# dump to the disk
	def dump
		
	end
	
	class << self
		# read from the disk
		def load
			
		end
	end
	
	def [](key)
		if @storage.nil?
			raise "ERROR: No data yet. Remember to run #fetch on #{self.class} objects to pull down data from the catalog, before trying to read data."
		end
		
		return @storage[key]
	end
	
	
	
	
	# NOTE: this method is for testing only.
	# * Copy over code from #fetch 
	# * move code to output full page type signature BEFORE running type search
	# * replace #signature_match? wih #test_signature_match?
	def test_types
		# GET THE DATA USING NOKOGIRI
		xml = Nokogiri::HTML(open(@url))
		chunk = xml.css('td.block_content_popup')
			Utilities.write_to_file("./course.html", chunk)
		
		
		
		# === figure out where the interesting section is, and store in 'segment' variable
		list = chunk.children
		
		i_start = list.find_index{  |x| x.name == "h1" }
		i_end   = list.find_index{  |x| x.name == "div" and x["style"] == "float: right" }
		
		
		segment = list[(i_start..i_end)]
		
		
		# === Classify Type of Course Info Page
		# === Based on the type, perform different parsing
		# 
		# Based on the names of tags the Aray 'segment',
		# various different types of course info pages can be identified
		# 
		# Each type signature is associated with a different callback for parsing that page layout.
		# (some minor code duplication, but this structure is very flexible.)
		info_page_types = {
			:type_a => {
				:signature => %w[h1 text br text br text a span text hr],
				:callback  => ->(){
					puts "=> TYPE A"
				}
			},
			
			:type_b => {
				:signature => %w[h1 p hr text p   p p text p],
				:callback  => ->(){
					puts "=> TYPE B"
				}
			},
			
			:type_c => {
				:signature => %w[h1 text br a], # never any <hr> dividing the header from body,
				:callback  => ->(){
					puts "=> TYPE C"
				}
			}
		}
		
		
		p chunk.children.collect{|x| x.name}[3..-1].join(' ')
		
		# Ordered list of types to check for.
		# Will attempt to match types higher up on the list, before types lower in the list
		
		# NOTE: *** Reorder this list to change search priority ***
		type_search_order = [
			:type_a,
			:type_b,
			:type_c
		]
		# ---
		success_flag = 
			type_search_order.any? do |name|
				type = info_page_types[name]
				
				if test_signature_match?(segment, type[:signature])
					# when a matching signature is found,
					# run the callback, and then do not look for any other potential callbacks
					type[:callback].call()
					
					# pseudo-return for the block
					true
				end
			end
		# ---
		unless success_flag
			raise "ERROR: Course info page in an unexpected format. See data dump above, or stack trace below."
		end
		
		
		
		# This method must always raise an error, because it is being called from
		# foo14, which uses the structure of foo11,
		# which only prints debug info when errors are thrown
		# (Really want to maintain similarity betwen foo14 and foo11.)
		# (Will certainly make code easier to maintain in the long-run)
		raise
	end
	
	
	
	
	private
	
	def signature_match?(node_list, type_signature)
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
	def test_signature_match?(node_list, type_signature)
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

	
	def parse_heading(h1_node)
		@title = h1_node.inner_text.strip # <h1>
		
		@title = @title.split(' - ').last
	end
	
	def parse_top_chunk(segment)
		@credits    = segment[0].inner_text.split(':').last.strip
		@attempts   = segment[2].inner_text.strip
		@department = segment[5].inner_text.strip # <a>, href dept. page in the catalog
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



end
