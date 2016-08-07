module SummerResearch

class DependencyGraph < RGL::DirectedAdjacencyGraph
	include RGL::BidirectionalGraph
	
	
	# Interface Improvements
	# If these methods are called without blocks, the return Enumerators, as expected
	def each_vertex
		return enum_for(:each_vertex) unless block_given?
		
		super do |v|
			yield v
		end
	end
	
	def each_edge
		return enum_for(:each_edge) unless block_given?
		
		super do |u,v|
			yield u,v
		end
	end
	
	
	def vertices
		return super()
	end
	
	def edges
		return self.each_edge.to_a
	end
	
	
	
	
	
	
	# add this to speed up #each_in_neighbor
	def add_vertex(vert)
		super(vert)
		@reverse = self.reverse
	end
	
	def add_edge(u,v)
		super(u,v)
		@reverse = self.reverse
	end
	
	# implement this to complete the interface RGL::BidirectionalGraph
	def each_in_neighbor(vert)
		@reverse.each_adjacent(vert)
	end
	
	
	
	
	# verts are stored in a hash, so their equality test sholud be hash equality?
		# (hash {vert => set of adjacent verts})
		# not a real matrix at all
	
	# NOTE: dfs clumps by courses in a related chain. bfs clumps by local prereqs.
	
	def ancestors(vert)
		inner_enum = @reverse.dfs_iterator(vert)
		Enumerator.new do |y|
			inner_enum.each do |v|
				next if v == vert
				
				y.yield(v)
			end
		end
	end
	
	def parents(vert)
		self.each_in_neighbor(vert)
	end
	
	def children(vert)
		self.each_adjacent(vert)
	end
	
	def descendants(vert)
		inner_enum = self.dfs_iterator(vert)
		Enumerator.new do |y|
			inner_enum.each do |v|
				next if v == vert
				
				y.yield(v)
			end
		end
	end
	
	
	
	# cut the graph below the given vert
	# (results in two subgraphs)
	def cut(vert)
		return unless self.has_vertex? vert
		
		new_name = "#{vert}_"
		
		# create the new target node
		# (the old one should still also exist in the graph)
		self.add_vertex(new_name)
		
		# get the children of the specified node, and rename their parents to the new target
		self.children(vert).each do |child|
			self.each_edge.select{ |dep, course|
				dep == vert && course == child
			}.each{ |dep, course|
				self.remove_edge  dep, course
				# self.add_edge     new_name, course
			}
		end
		
	end
	
	
	def rename_vert(old_vert_name, new_vert_name)
		
	end
	
	
	
	
	def add_constraint()
		
	end
	
	# export nodes and edges to JSON
	# as well as constraints
	def to_json_d3v3_cola(required_courses, elective_courses, elective_category)
		vert_to_i_table = self.vertices.each_with_index.to_a.to_h
		
		
		out = Hash.new
		
		out['nodes'] = 
			self.vertices.each_with_index.collect do |v, i|
				type = node_type(v, required_courses, elective_courses)
				class_string = type.to_s.tr('_', '-')
				
				elective_type =
					if type == :elective
						elective_category[v]*2
					else
						-1
					end
				
				
				{
					'name' => v,
					'number' => i,
					'chain_deps' => ancestors(v).to_a.collect{  |x| vert_to_i_table[x]  },
					'class' => class_string,
					'elective_type' => elective_type
				}
			end
		
		
		out['links'] = 
			self.each_edge.collect do |u,v|
				{
					'source' => vert_to_i_table[u],
					'target' => vert_to_i_table[v]
				}
			end
		
		out['constraints'] = constraints_foo()
		
		JSON.generate(out)
	end
	
	
	
	private
	
	
	def constraints_foo
		# basic constraint: prereqs go above later courses.
		# (overall visual flow: top to bottom as skill increases)
		# defined as local property.
		# graph ends up showing global properties.
		
		
		vert_conversion_table = self.vertices.each_with_index.to_a.to_h
		c1 =
			self.each_vertex.collect do |vert|
				self.parents(vert).collect do |dependency|
					i_left  = vert_conversion_table[vert]
					i_right = vert_conversion_table[dependency]
					
					{
						"axis" => "y", 
						"left" => i_left, "right" => i_right, "gap" => 25
					}
				end
			end
		c1.flatten!
		
		constraints = c1
		
		
		
		c2 = 
			self.vertices.select{ |vert|
				vert.include? '_'
			}.collect do |vert|
				dependency = vert.tr('_', '')
				
				i_left  = vert_conversion_table[vert]
				i_right = vert_conversion_table[dependency]
				
				{
					"axis" => "y", 
					"left" => i_left, "right" => i_right, "gap" => 25
				}
			end
		
		constraints += c2
		
		return constraints
	end
	
	
	
	
	
	def node_type(course_string, required_courses, elective_courses)
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
			:split_link
		else
			if required_courses.include? course_string
				# required course
				:required
			elsif elective_courses.include? course_string
				# an elective that can be applied to your major
				:elective
			else
				# non-required
				# (not an elective, but a non-core dependency)
				:not_required
			end
		end
		
		
		# '?' and elective.include? are competing for priority
	end
end

end



# Want to implement a Class to store the course data verts,
# that way you can annotate those classes, and thus annotate the actual graph.
# Then you can export the annotated graph to JSON or w/e format you need for rendering.
