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
	
	
	
	
	
	def add_constraint()
		
	end
	
	# export nodes and edges to JSON
	# as well as constraints
	def to_json_d3v3_cola
		vert_to_i_table = self.vertices.each_with_index.to_a.to_h
		
		
		out = Hash.new
		
		out['nodes'] = 
			self.vertices.each_with_index.collect do |v, i|
				{
					'name' => v,
					'number' => i,
					'chain_deps' => ancestors(v).to_a.collect{  |x| vert_to_i_table[x]  }
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
		
		return constraints
	end
end

end



# Want to implement a Class to store the course data verts,
# that way you can annotate those classes, and thus annotate the actual graph.
# Then you can export the annotated graph to JSON or w/e format you need for rendering.
