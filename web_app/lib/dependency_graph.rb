module SummerResearch

class DependencyGraph < RGL::DirectedAdjacencyGraph
	include RGL::BidirectionalGraph
	
	
	
	# add this to speed up #each_in_neighbor
	def add_vertex(vert)
		super(vert)
		@reverse = self.reverse
	end
	
	def add_edge(edge)
		super(edge)
		@reverse = self.reverse
	end
	
	# implement this to complete the interface RGL::BidirectionalGraph
	def each_in_neighbor(vert)
		@reverse.each_adjacent(vert)
	end
	
	
	
	
	# verts are stored in a hash, so their equality test sholud be hash equality?
		# (hash {vert => set of adjacent verts})
		# not a real matrix at all
	
	
	def ancestors(vert)
		@reverse.bfs_iterator(vert)
	end
	
	def parent(vert)
		self.each_in_neighbor(vert)
	end
	
	def children(vert)
		self.each_adjacent(vert)
	end
	
	def descendants(vert)
		self.bfs_iterator(vert)
	end
	
	
	
	
	
	def add_constraint()
		
	end
	
	# export nodes and edges to JSON
	# as well as constraints
	def to_json_d3v3_cola
		
	end
end

end



# Want to implement a Class to store the course data verts,
# that way you can annotate those classes, and thus annotate the actual graph.
# Then you can export the annotated graph to JSON or w/e format you need for rendering.
