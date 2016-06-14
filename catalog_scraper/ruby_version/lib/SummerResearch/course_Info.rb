module SummerResearch


class CourseInfo
	attr_reader :id, :url
	
	def initialize(course)
		@storage = Hash.new
		
		@id  = course.id
		@url = course.url
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
		
		
		
		
		# === figure out where the interesting section is
		
		
		
		# === extract the interesting section
		
		
		
		
		header = nil
		rest   = nil
		
		# Type A
		begin 
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
			
			heading = segment[0]
			top     = segment[1..6]
			rest    = segment[7..-1]
		rescue StandardError => e
			# don't actually do anything,
			# instead just move on to the next part of the code,
			# and process as a Type B pattern
			# 
			# (This is actually a fairly bad way of doing this, but the general idea of "pattern failed, try the next pattern" is pretty cool)
		end
		
		
		
		# Type B
		begin
			raise if heading and top and rest
			# skip this block if the values are already set
			
			
			heading = segment
			top     = segment
			rest    = segment
		rescue StandardError => e
			# actually don't want to do this.
			# the way I'm handling tranisition between these cases needs work
			
			# If there is actually an "error" with the expected data, 
			# (not the form that was expected)
			# then that will eventually show up in the code below,
			# as the actual parsing will fail, and throw an execption.
		end
		
		
		
		
		# Unified processing, regaurdless of where the pieces are located
		heading_data = parse_heading(heading)
		top_data     = parse_top_chunk(top)
		body_data    = parse_body(rest)
		
		# p [heading_data.class, top_data.class, body_data.class]
		
		@storage = heading_data.merge(top_data).merge(body_data)
		
		return self
		
		
		
		
		
		
		
		
		# junk on top
		# header
		# body
			# BRANCH
			# Type A
			
			
			# Type B
			
			
		# link to PatriotWeb THIS Semester
		# link to PatriotWeb NEXT Semester
		# junk on bottom		
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
		return @storage[key]
	end
	
	
	
	private
	
	
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
		out = Hash.new
		
		out["Title"] = h1_node.inner_text.strip # <h1>
		
		return out
	end
	
	def parse_top_chunk(segment)
		out = Hash.new
		
		out["Credits"]    = segment[0].inner_text.split(':').last.strip
		out["Attempts"]   = segment[2].inner_text.strip
		out["Department"] = segment[5].inner_text.strip # <a>, href dept. page in the catalog
		
		return out
	end
	
	def parse_body(segment)
		out = Hash.new
		
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
	
	def body_TypeA
		
	end
	
	def body_TypeB
		
	end
end



end
