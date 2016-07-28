module Models
	class ComputerScience_BS

attr_reader :data

def initialize
	@data = raw_data()
	
	@required = nil # set of all required courses
	
	
	# all the courses that will populate @data, in one hash
	# (realistically, this should be the most raw form of the data, after parsing the HTML from the catalog, as far as the front-end is concerned)
	@all = {
		"CS 101"=>["CS 112"],
		"CS 105"=>[],
		"CS 112"=>["MATH 104_", "MATH 105_", "MATH 113_"],
		"CS 211"=>["CS 112"],
		"CS 262"=>["CS 211", "CS 222"],
		"CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"],
		"CS 310"=>["CS 211", "MATH 113_", "CS 105"],
		"CS 321"=>["CS 310", "ENGH 302"],
		"CS 330"=>["CS 211", "MATH 125_"],
		"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
		"CS 465"=>["CS 367"],
		"CS 483"=>["CS 310", "CS 330", "MATH 125_"],
		"ECE 301"=>["MATH 125_", "MATH 112_"],
		"COMM 100"=>[],
		"MATH 113"=>["MATH 104", "MATH 105"],
		"MATH 114"=>["MATH 113", "MATH 123", "MATH 124"],
		"MATH 125"=>["MATH 105", "MATH 108", "MATH 113"],
		"MATH 203"=>["MATH 114", "MATH 116"],
		"MATH 213"=>["MATH 114", "MATH 116"],
		"STAT 344"=>["MATH 114", "MATH 116"],
		"CS 482"=>["CS 310", "MATH 203", "STAT 344"],
		"CS 484"=>["CS 310", "STAT 344"],
		"CS 485"=>["CS 262", "CS 310", "MATH 203"],
		"CS 463"=>["CS 330", "CS 367"],
		"CS 469"=>["CS 330", "CS 367", "STAT 344"],
		"CS 475"=>["CS 310", "CS 367"],
		"CS 451"=>["MATH 203", "CS 310", "CS 367"],
		"CS 455"=>["CS 310", "CS 367", "STAT 344"],
		"CS 468"=>["CS 310", "CS 367"],
		"CS 477"=>["CS 310", "CS 367"],
		"CS 471"=>["CS 310", "CS 367", "ECE 445"],
		"CS 450"=>["CS 310", "CS 330"],
		"CS 480"=>["CS 310", "CS 330"],
		"CS 425"=>["CS 310", "CS 351"],
		"CS 440"=>["CS 310", "CS 330", "CS 367"],
		"CS 490"=>["CS 321", "CS 483"],
		
		"CS 499"=>[],
		# this is special topics, so prereqs unknown
	
		"MATH 446"=>["MATH 203", "CS 112"]
	}
end

def json
	data = self.data()
	
	
	dataset = (
		@data[:required].collect{  |clump| clump.keys }.flatten + 
		@data[:elective].each_value.collect{|clump| clump.keys  }.flatten
	)
	
	
	
	d1 = 
		@data[:required].collect do |clump|
			{
				'nodes' => nodes(clump),
				'links' => links(clump)
			}
		end
	
	d2 = 
		@data[:elective].each.collect do |name, clump|
			{
				'nodes' => nodes(clump),
				'links' => links(clump)
			}
		end
	
	out = d1 + d2
	
	
	
	
	
	
	# mark nodes with different colors
	required =
		@data[:required].collect{  |clump|  clump.to_a  }
		.flatten
		.to_set
	
	elective = 
		@data[:elective].values.collect{  |clump|  clump.to_a  }
		.flatten
		.to_set
	
	out.each do |clump_data|
		clump_data['nodes'].each do |node|
			node['color'] = color(node['id'], required)
		end
	end
	
	
	JSON.generate out
end



def json_list_all_courses
	out = @all.collect{|k,v| [k,v ]}.flatten
	
	JSON.generate out
end


private




# generate all nodes to make a graph, for a clump of data
def nodes(data)
	nodes = 
		data.collect{  |k,v|   [k, v] }.flatten.uniq
			.collect do |data|
				{
					'id' => data,
					'r' => data.split(' ')[1][0].to_i, # first digit
				}
			end
	
	return nodes
end

# generate all the edges to made a graph, for a clump of data
def links(data)
	links =
		data.collect do |course, deps|
			deps.collect do |dependency|
				[course, dependency]
			end
		end
	links =
		links.flatten(1).collect do |course, dependency|
			{
				'source' => dependency,
				'target' => course,
				'color'  => '#3399FF'
			}
		end
	
	return links
end


def color(course_string, required)
	# if course_string.split(' ')[0] != 'CS'
		# "#10D588"
	if required.include? course_string
		# required course
		"#000"
	elsif course_string.include? '_'
		# link to another sub-graph
		"#000"
	else
		# non-required
		# (not an elective, but a non-core dependency)
		"#AAA"
	end
end



def raw_data
	data =
	{
		"CS 101"=>["CS 112"],
		"CS 105"=>[],
		"CS 112"=>["MATH 104", "MATH 105", "MATH 113"],
		"CS 211"=>["CS 112"],
		"CS 262"=>["CS 211", "CS 222"],
		"CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"],
		"CS 310"=>["CS 211", "MATH 113", "CS 105"],
		"CS 321"=>["CS 310", "ENGH 302"], # "CS 421", "SWE 421", "CS 321"
		"CS 330"=>["CS 211", "MATH 125"],
		"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
		"CS 465"=>["CS 367"],
		"CS 483"=>["CS 310", "CS 330", "MATH 125"],
		"ECE 301"=>["MATH 125", "MATH 112"]
	}
	
	# manually tweaked
	data = {
		"CS 101"=>["CS 112"],
		"CS 105"=>[],
		"CS 112"=>["MATH 104_", "MATH 105_", "MATH 113_"],
		"CS 211"=>["CS 112"],
		"CS 262"=>["CS 211", "CS 222"],
		"CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"],
		"CS 310"=>["CS 211", "MATH 113_", "CS 105"],
		"CS 321"=>["CS 310", "ENGH 302"],
		"CS 330"=>["CS 211", "MATH 125_"],
		"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
		"CS 465"=>["CS 367"],
		"CS 483"=>["CS 310", "CS 330", "MATH 125_"],
		"ECE 301"=>["MATH 125_", "MATH 112_"],
		"COMM 100"=>[],
		
		# "MATH 113"=>["MATH 104", "MATH 105"],
		# "MATH 114"=>["MATH 113", "MATH 123", "MATH 124"],
		# "MATH 125"=>["MATH 105", "MATH 108", "MATH 113"],
		# "MATH 203"=>["MATH 114", "MATH 116"],
		# "MATH 213"=>["MATH 114", "MATH 116"],
		# "STAT 344"=>["MATH 114", "MATH 116"]
	}
	# return data
	
	
	# list of 'clumps'
	# each each clump generates a separate graph
	# ideally, each graph has no knots (formal constraint)
	# but really, make the graphs easy to read (human constraint)
	
	# how to split:
	# * separate a graph into two groups, top and bottom
	# * add '_' to the end of all dependencies in the top group
	# * add '_' to the end of all parent courses in the bottom group
	# * separate the top and bottom groups into separate 'clumps'
	# * remove underscores from the parent courses in bottom group clump
	# (bascially, mark so you know where to split, try out the split in the same graph, and then separate out into two different graphs)

	# This data creates simple but still kinda ugly graphs.
	# For now, have a person look at this data and manually make a good graph.
	# Later on, maybe try to automate this?
	
	
	
	# use all strings, no symbols, because this will be converted to JSON and sent to the client
	clumped_data = {
		:required => [
			# all required, but separated into unknotted clumps
			{
				"CS 101"=>["CS 112"],
				"CS 105"=>[],
				"CS 112"=>["MATH 104_", "MATH 105_", "MATH 113_"],
				"CS 211"=>["CS 112"],
				"CS 262"=>["CS 211", "CS 222"],
				"CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"],
				"CS 310"=>["CS 211", "MATH 113_", "CS 105"],
				"CS 321"=>["CS 310", "ENGH 302"],
				"CS 330"=>["CS 211", "MATH 125_"],
				"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
				"CS 465"=>["CS 367"],
				"CS 483"=>["CS 310", "CS 330", "MATH 125_"],
				"ECE 301"=>["MATH 125_", "MATH 112_"],
				"COMM 100"=>[],
			},
			
			{
				"MATH 113"=>["MATH 104", "MATH 105"],
				"MATH 114"=>["MATH 113", "MATH 123", "MATH 124"],
				"MATH 125"=>["MATH 105", "MATH 108", "MATH 113"],
				"MATH 203"=>["MATH 114", "MATH 116"],
				"MATH 213"=>["MATH 114", "MATH 116"],
				"STAT 344"=>["MATH 114", "MATH 116"]
			}
		],
		
		:elective => { # clump by prereqs
			# there is a short list of classe that gate the upper level stuff in the CS department:
			# CS 310, 330, 367;  CS 321, 483;  CS 112 (gates math)
			
			
			"310" => 
			{
				"CS 482"=>["CS 310", "MATH 203", "STAT 344"],
				"CS 484"=>["CS 310", "STAT 344"],
				"CS 485"=>["CS 262", "CS 310", "MATH 203"],
			},
			
			"330 367" => 
			{
				"CS 463"=>["CS 330", "CS 367"],
				"CS 469"=>["CS 330", "CS 367", "STAT 344"]
			},
			
			"310 367" => 
			{
				"CS 475"=>["CS 310", "CS 367"],
				"CS 451"=>["MATH 203", "CS 310", "CS 367"],
				"CS 455"=>["CS 310", "CS 367", "STAT 344"],
				"CS 468"=>["CS 310", "CS 367"],
				"CS 477"=>["CS 310", "CS 367"],
				"CS 471"=>["CS 310", "CS 367", "ECE 445"]
			},
			
			"310 330" => 
			{
				"CS 450"=>["CS 310", "CS 330"],
				"CS 480"=>["CS 310", "CS 330"]
			},
			
			"310 351" => 
			{
				"CS 425"=>["CS 310", "CS 351"]
			},
			
			"310 330 367" => 
			{
				"CS 440"=>["CS 310", "CS 330", "CS 367"]
			},
			
			
			
			
			
			"others" => {
				"CS 490"=>["CS 321", "CS 483"],
				
				"CS 499"=>[],
				# this is special topics, so prereqs unknown
				
				"MATH 446"=>["MATH 203", "CS 112"]
			}
		}
	}


	# take this data, and then give it at least three separate colors:
	# * required
	# * elective
	# * non-required dependencies to electives

	# * links? ()
	
	
	return clumped_data
end










end
end
