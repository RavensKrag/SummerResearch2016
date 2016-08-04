# require 'rubygems'
# require 'rake'

module Models
	class ComputerScience_BS

path_to_file = File.expand_path(File.dirname(__FILE__))
MODEL_ROOT = File.expand_path('./', path_to_file)

attr_reader :data

def initialize
	@data = raw_data()
	
	@required = nil # set of all required courses
	
	
	# all the courses that will populate @data, in one hash
	# (realistically, this should be the most raw form of the data, after parsing the HTML from the catalog, as far as the front-end is concerned)
	@all_data = {
		"CS 101"=>["CS 112"],
		"CS 105"=>[],
		"CS 112"=>["MATH 104", "MATH 105", "MATH 113"],
		"CS 211"=>["CS 112"],
		"CS 262"=>["CS 211", "CS 222"],
		"CS 306"=>["CS 105", "COMM 100", "ENGH 302", "HNRS 110", "HNRS 122", "HNRS 130", "HNRS 131", "HNRS 230", "HNRS 240"],
		"CS 310"=>["CS 211", "MATH 113", "CS 105"],
		"CS 321"=>["CS 310", "ENGH 302"],
		"CS 330"=>["CS 211", "MATH 125"],
		"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
		"CS 465"=>["CS 367"],
		"CS 483"=>["CS 310", "CS 330", "MATH 125"],
		"ECE 301"=>["MATH 125", "MATH 112"],
		"MATH 113"=>["MATH 104", "MATH 105"],
		"MATH 114"=>["MATH 113", "MATH 123", "MATH 124"],
		"MATH 125"=>["MATH 105", "MATH 108", "MATH 113"],
		"MATH 203"=>["MATH 114", "MATH 116"],
		"MATH 213"=>["MATH 114", "MATH 116"],
		"STAT 344"=>["MATH 114", "MATH 116"],
		"COMM 100"=>[],
		
		"CS 463"=>["CS 330", "CS 367"],
		"CS 471"=>["CS 310", "CS 367", "ECE 445"],
		"CS 475"=>["CS 310", "CS 367"],
		"CS 425"=>["CS 310", "CS 351"],
		"CS 440"=>["CS 310", "CS 330", "CS 367"],
		"CS 450"=>["CS 310", "CS 330"],
		"CS 451"=>["MATH 203", "CS 310", "CS 367"],
		"CS 455"=>["CS 310", "CS 367", "STAT 344"],
		"CS 468"=>["CS 310", "CS 367"],
		"CS 469"=>["CS 330", "CS 367", "STAT 344"],
		"CS 477"=>["CS 310", "CS 367"],
		"CS 480"=>["CS 310", "CS 330"],
		"CS 482"=>["CS 310", "MATH 203", "STAT 344"],
		"CS 484"=>["CS 310", "STAT 344"],
		"CS 485"=>["CS 262", "CS 310", "MATH 203"],
		"CS 490"=>["CS 321", "CS 483"],
		"CS 499"=>[], # this is special topics, so prereqs unknown
		"MATH 446"=>["MATH 203", "CS 112"],
		"OR 481"=>["MATH 203", "CS 112"],
		"STAT 354"=>["STAT 346", "STAT 344"],
		"OR 335"=>["CS 112", "STAT 344", "STAT 346", "MATH 351", "CS 211"],
		"OR 441"=>["MATH 203"],
		"OR 442"=>["STAT 344", "STAT 346", "MATH 351"],
		"ECE 280"=>["PHYS 260", "PHYS 261", "ECE 220", "ECE 280"],
		"ECE 431"=>["ECE 331", "ECE 333"],
		"ECE 447"=>["ECE 445", "CS 367", "CS 222"],
		"ECE 450"=>["CS 112", "ECE 280", "ECE 331", "ECE 332", "ECE 301"],
		"ECE 511"=>["ECE 445"],
		"SWE 432"=>["MATH 125", "CS 310"],
		"SWE 437"=>["MATH 125", "CS 310"],
		"SWE 443"=>["CS 321", "CS 421", "SWE 321", "SWE 421"],
		"SYST 371"=>["SYST 210", "SYST 330"],
		"SYST 470"=>["SYST 210", "STAT 344"],
		"PHIL 371"=>[],
		"ENGH 388"=>["ENGL 302", "ENGH 302"], "PHIL 376"=>["PHIL 173", "MATH 110"]
	}
	
	
	
	
	@rake = Rake::Application.new
	
	Dir.chdir MODEL_ROOT do
		puts "LOAD START?"
		Rake.application = @rake
		@rake.init
		@rake.load_rakefile() # uses the working directory? wow that's weird
		puts "LOAD END!"
	end
end


def json
	d1 = 
		@data[:required].collect do |clump|
			{
				'nodes' => nodes(clump),
				'links' => links(clump)
			}
		end
	
	d2 = 
		@data[:elective].each.collect do |name, clump|
			if name != 'others'
				# for the clumped groups, remove the common deps, replace with a single node
				
				clump.values.each do |dep_list|
					name.split.each do |course_number|
						course = "CS #{course_number}"
						puts course
						dep_list.delete course
					end
					
					dep_list << "? #{name}"
				end
			end
			
			{
				'name'  => name,
				'nodes' => nodes(clump),
				'links' => links(clump)
			}
		end
	
	d3 =
		[
			{
				'nodes' => nodes(@all_data),
				'links' => links(@all_data)
			}
			
		]
	
	out = d3 + d1 + d2
	# out = d3
	
	
	
	# mark nodes with different colors
	@color_key ||= {
		:gated_elective_clump      => "#10D588",  # light green
		:link_to_other_graph       => "#3399FF",  # blue
		
		:required_course           => "#CC2300",  # red / orange
		:elective_for_requirements => "#242424",  # black
		:not_required              => "#AAA"      # grey
	}
	
	required =
		@data[:required].collect{  |clump|  clump.keys  }
		.flatten
		.to_set
	
	elective = 
		@data[:elective].values
		.collect{  |clump|  clump.keys  }
		.flatten
		.to_set
	
	leaves = Array.new
	out.each do |clump_data|
		clump_data['nodes'].each do |node|
			# --- color assigment
			type = node_type(node['id'], required, elective)
			node['color'] = @color_key[type]
			
			
			# --- do other things with type
			leaves << node['id'] if type == :not_required
		end
	end
	
	Models::Utilities.write_to_file(
		'./leaves.yaml', leaves.uniq.to_yaml
	)
	# need to recursively add all children of these leaves
	# to the graph
	# 
	# they should all be typed as :not_required,
	# because their parent courses are already :not_required
	
	
	JSON.generate out
end



def json_list_all_courses
	out = @all_data.collect{|k,v| [k,v ]}.flatten
	
	JSON.generate out
end


# output data for directonal Cola all-arrows-point-down graph
# data   -- backend information
# public -- information that can be exposed to the outside world
# out    -- static files to be vendored
def json_directional(name, logger)
	# return '{"nodes":[], "links":[], "constraints":[]}'
	
	relative_filepath = "./#{name}.yaml"
	
	
	public_data_dir = File.expand_path('./public', MODEL_ROOT)
	filepath = File.expand_path(relative_filepath, public_data_dir)
	
	
	raise "No data exists for '#{name}'" unless File.exist? filepath
	
	
	
	
	raw_data2 = YAML.load_file filepath
	
	
	
	# input sanitization???
	# I mean, the name is coming from a URL piece, so it could be anything...
	'CS_BS_all.yaml'
	logger.info @rake.methods.grep(/task/).inspect
	logger.info @rake.tasks.inspect
	@rake['public/CS_BS_all.yaml']
	
	
	
	
	# logger.info raw_data2.to_yaml
	
	# File.open(filepath, 'w') do |f|
	# 	f.puts raw_data2.to_yaml
	# end
	
	
	chains = Models::Utilities.load_yaml_file(
		'data/CS_BS_dep_chains.yaml'
	).to_h
	# logger.info chains.inspect
	
	
	# === create nodes
	nodes = nodes(raw_data2)
	nodes.each do |h|
		h['name'] = h['id']
		h.delete 'id'
	end
	nodes.each_with_index do |h, i|
		h['number'] = i
	end
	nodes.each do |h|
		# annotate node with names of all its ancestors
		logger.info h['name']
		
		deps = chains[h['name']] || []
		chain_deps = 
			deps.collect do |name|
				nodes.find_index{ |x| x['name'] == name}
			end
		
		logger.info chain_deps.compact.inspect
		h['chain_deps'] = chain_deps.compact
	end
	
	# === create links (edges)
	links = links(raw_data2)
	links.each do |h| 
		h['source'] = nodes.find_index{ |x| x['name'] == h['source']}
		h['target'] = nodes.find_index{ |x| x['name'] == h['target']}
	end
	links.each do |h|
		h.delete 'color'
	end
	
	links.each do |h|
		if h['source'] == h['target']
			raise "ERROR: #{h.inspect}"
		end
	end
	
	
	# === Create Constraints
	# basic constraint: prereqs go above later courses.
		# (overall visual flow: top to bottom as skill increases)
		# defined as local property.
		# graph ends up showing global properties.
	c1 =
		raw_data2.collect do |course, deps|
			deps.collect do |d|
				i_left  =
					nodes.find_index{ |x| x['name'] == course}
				
				i_right =
					nodes.find_index{ |x| x['name'] == d}
				
				
				{
					"axis" => "y", 
					"left" => i_left, "right" => i_right, "gap" => 25
				}
			end
		end
	c1.flatten!
	
	constraints = c1
	
	# TODO: implement constraint such that all 100-level courses are above the 200-level ones, etc etc.
	# (want to stratify course levels)
	# logger.info "HEY"
	gap = 500
	c2 =
		nodes.combination(2)
		.collect{  |n1, n2| # isolate the names
			[n1['name'], n2['name']]
		}
		.select{   |n1, n2| # filter by course number
			logger.info [n1,n2].inspect
			a,b = [n1, n2].collect{|x| x.split.last[0].to_i }
			
			a > 3
		}.collect{ |n1, n2|
			i_left  =
				nodes.find_index{ |x| x['name'] == n1}
			
			i_right =
				nodes.find_index{ |x| x['name'] == n2}
			
			{
				"axis" => "y", 
				"left" => 28, "right" => i_left, "gap" => gap
			}
		}
	
		# this constraint currently has no effect on the output
	constraints = constraints + c2
	constraints.flatten!
	
	
	
	# all nodes want to have horizontal spacing
	gap = 25
	c3 =
		nodes.combination(2)
		.collect{  |n1, n2| # isolate the names
			[n1['name'], n2['name']]
		}
		.select{   |n1, n2| # filter by course number
			logger.info [n1,n2].inspect
			a,b = [n1, n2].collect{|x| x.split.last[0].to_i }
			
			a > 3
			true
		}.collect{ |n1, n2|
			i_left  =
				nodes.find_index{ |x| x['name'] == n1}
			
			i_right =
				nodes.find_index{ |x| x['name'] == n2}
			
			{
				"axis" => "x", 
				"left" => i_left, "right" => i_right, "gap" => gap
			}
		}
	
		# this constraint currently has no effect on the output
	constraints = constraints + c3
	constraints.flatten!
	
	
	
	
	# TODO: implement constraint that causes all courses from a single department to clump
	
	
	
	
	
	# === additional processing on the graph
	
	
	
	
	
	
	
	# === rough packaging for output
	out = {
		# 'name'  => name,
		'nodes' => nodes,
		'links' => links,
		'constraints' => constraints
	}
	
	
	# === style the nodes
	
	color_key ||= {
		:gated_elective_clump      => "#10D588",  # light green
		:link_to_other_graph       => "#3399FF",  # blue
		
		:required_course           => "#CC2300",  # red / orange
		:elective_for_requirements => "#242424",  # black
		:not_required              => "#AAA"      # grey
	}
	
	required =
		@data[:required].collect{  |clump|  clump.keys  }
		.flatten
		.to_set
	
	elective = 
		@data[:elective].values
		.collect{  |clump|  clump.keys  }
		.flatten
		.to_set
	
	
	out['nodes'].each do |node|
		# --- color assigment
		type = node_type(node['name'], required, elective)
		# node['color'] = color_key[type]
		node['class'] = type.to_s.tr('_', '-')
		
		
		# --- do other things with type
		# leaves << node['id'] if type == :not_required
	end
	
	
	
	
	# === Highlight nodes with many children
	nodes.each_with_index
	.collect{   |n, i|   i }
	.select{    |i|
		children = links.select{|link| link['source'] == i }.length
		children > 5
	}.collect{  |i|
		nodes[i]
	}.each do   |n|
		n['class'] = [n['class'], "bottleneck"].join(' ')
	end
	
	
	
	
	# === style the edges
	
	
	
	
	# === final output
	return JSON.generate out
end



def all_courses
	10.times { puts "HEY"}
	p @all_data.to_a.flatten.uniq
	
	return @all_data.to_a.flatten.uniq
end


private




# generate all nodes to make a graph, for a clump of data
def nodes(data)
	nodes = 
		data.collect{  |k,v|   [k, v] }.flatten.uniq
			.collect do |data|
				{
					'id' => data
					# 'r' => data.split(' ')[1][0].to_i, # first digit
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


def node_type(course_string, required, elective)
	# if course_string.split(' ')[0] != 'CS'
		# "#10D588"
	# if course_string.split.collect{|x| x.to_i }.include? 0
	# 	# something in the list was not a number.
	# 	# normal department codes were given
	# else
		
	# end
	
	
	
	if course_string.include? '?'
		# elective clump gated by one or more courses
		:gated_elective_clump 
	elsif course_string.include? '_'
		# link to another sub-graph
		:link_to_other_graph
	else
		if required.include? course_string
			# required course
			:required_course
		elsif elective.include? course_string
			# an elective that can be applied to your major
			:elective_for_requirements
		else
			# non-required
			# (not an elective, but a non-core dependency)
			:not_required
		end
	end
	
	
	# '?' and elective.include? are competing for priority
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
				"SWE 432"=>["MATH 125", "CS 310"], 
				"SWE 437"=>["MATH 125", "CS 310"], 
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
				# required courses
				# duplicated here again, for use as glue
				"CS 112"=>["MATH 104_", "MATH 105_", "MATH 113_"],
				"CS 211"=>["CS 112"],
				"CS 262"=>["CS 211", "CS 222"],
				"CS 321"=>["CS 310", "ENGH 302"],
				"CS 367"=>["CS 262", "CS 222", "ECE 301", "ECE 331"],
				"CS 310"=>["CS 211", "MATH 113", "CS 105"],
				
				
				
				# --- gated by CS
				"CS 490"=>["CS 321", "CS 483"],
				"SWE 443"=>["CS 321", "CS 421", "SWE 321", "SWE 421"], 
				
				"CS 499"=>[],
				# this is special topics, so prereqs unknown
				
				
				"OR 441"=>["MATH 203"], 
				"MATH 446"=>["MATH 203", "CS 112"],
				"OR 481"=>["MATH 203", "CS 112"],
				"ECE 450"=>["CS 112", "ECE 280", "ECE 331", "ECE 332", "ECE 301"], 
				
				
				"OR 335"=>["CS 112", "STAT 344", "STAT 346", "MATH 351", "CS 211"], 
				
				"ECE 447"=>["ECE 445", "CS 367", "CS 222"], 
				
				
				
				# --- gated by something else
				
				"STAT 354"=>["STAT 346", "STAT 344"], 
				"OR 442"=>["STAT 344", "STAT 346", "MATH 351"], 
				
				"SYST 470"=>["SYST 210", "STAT 344"], 
				
				"ECE 280"=>["PHYS 260", "PHYS 261", "ECE 220", "ECE 280"], 
				"ECE 431"=>["ECE 331", "ECE 333"], 
				
				"ECE 511"=>["ECE 445"], 
				
				
				
				"SYST 371"=>["SYST 210", "SYST 330"], 
				"PHIL 371"=>[], 
				"PHIL 376"=>["PHIL 173", "MATH 110"],
				"ENGH 388"=>["ENGL 302", "ENGH 302"], 
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
