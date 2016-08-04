module SummerResearch


class DependencyParser
	PATTERNS = [
		[/(Mason Core)/,   :core_overview],
		
		[
			/(#{ %w[UWCU UOC UQR UITC UFA UGU ULIT UNSL USBS UWC USYN].join('|') })/,
			:core_category
		],
		# Exhaustive search for all "mason core" category keys
		# (must trigger before searching for department codes)
		
		[/(\d{3})(-level)/,  :year_level_category],
		# ex: 600-level course
		
		[/(\p{Lu}{2,4})/,  :department_code],
		# 2-4 capital letters,
		
		[/(\d{3})/,        :course_number],
		# 3 digits,
		
		[/(C or higher|(g|G)rade of C or better)/, :c_or_higher], # above 'of something'
		
		
		[/(\d+ (credits|credit hours))/,  :credit_count], # above 'of something'
		# ooh, this is a multi-fragment token...,
		
		[/(permission of instructor)/, :instructor_permission], # above 'of something'
		
		
		# [/(of)/,           :OF], # above 'of something'
		
		
		[/(of \w*)/,       :of_something],
		# as in '60 credits of philosophy'
		
		
		# [/(and)/,                      :AND],
		[/(or)/,                       :OR],
		
		[/(specific prerequisites vary)/, :it_depends]
	]
	
	# $1 through $9 are the "Pseudo Variables" set by regex matching
		# src: http://stackoverflow.com/questions/6803647/how-to-write-a-ruby-switch-statement-case-when-with-regex-and-backreferences
	
	
	# NOTE: assuming the only usage of three-digit numbers is in course codes. However, some courses gate by the number of credits, so maybe a three-digit number could appear there? It seems unlikely, (60 and 90 seem like better choices, given 120 to graduate) but making a note in case an error comes up in the future.
	
	
	class << self
	
	def call(all_deps_text)
		# === find relevant "tokens"
		
		tokens = lex(PATTERNS, all_deps_text)
		out = parse(tokens)
		
		return out
	end
	
	
	private
	
	def lex(patterns, corpus)
		# foo = patterns[0]
		# all_deps_text.scan foo[0] do
		# 	p [$~.offset(1), foo[1]].flatten
		# end
		
		
		# p patterns[0][0].match(all_deps_text)
		
		
		tokens = 
			patterns.collect do |regexp, type|
				matchdata_list = corpus.to_enum(:scan, regexp).collect { Regexp.last_match }
				
				matchdata_list.collect do |matchdata|
					start = matchdata.begin(0) # nth item in the matchdata collection
					stop  = matchdata.end(0)
					captures = matchdata.captures
					
					[start, stop, type, captures]
				end
			end
		
		tokens = tokens.flatten(1).sort_by do |start_pos, end_pos, type, captures|
			start_pos
		end
		
		
		# --- remove overlapping tokens
		# whatever token whose pattern is higher on the list stays (lower index)
		# the other token gets deleted
		removal_list = Array.new
		tokens.each_with_index do |t1, i|
			tokens[(i+1)..-1].each do |t2|
				t1_start, t1_stop = t1[0..1]
				t2_start, t2_stop = t2[0..1]
				
				removal_list << [t1, t2] if (t1_start..t1_stop).include? t2_start
			end
		end
		
		removal_list.uniq.each do |t1, t2|
			type1 = t1[2]
			type2 = t2[2]
			
			a = patterns.each_with_index.find_index{  |pat,i|  pat[1] == type1  }
			b = patterns.each_with_index.find_index{  |pat,i|  pat[1] == type2  }
			# p [a,b]
			
			if a > b
				tokens.delete t1
			else
				tokens.delete t2
			end
			
		end
		
		
		
		# --- print data dump to file, for debugging	
		dump = tokens.collect{|t| t.inspect }.join("\n")
		Models::Utilities.write_to_file('data/dep_parser_dump.txt', dump)
		
		
		
		# tokens.
		
		
		
		return tokens
	end

	def parse(tokens)
		# === use "tokens" to assemble course names
		return if tokens.empty?
		# puts "running"
		
		
		out = Array.new
		
		
		# --- parse complex generalized case like '3 credits of 100 or 200-level COMM'
		
		# [1138, 1147, :credit_count, ["3 credits", "credits"]]
		# [1151, 1154, :course_number, ["100"]]
		# [1158, 1167, :year_level_category, ["200", "-level"]]
		# [1168, 1172, :department_code, ["COMM"]]
		
		foo_data_new = Array.new
		
		
		tokens.each_with_index do |t, i|
			break if i == tokens.size-1 # need to read one past 'i', so abort when 'i' is max
			
			start_pos, end_pos, type, captures = t
			
			next unless type == :year_level_category
			end_index = i+1
			
			
			
			next unless tokens[end_index][2] == :department_code
			
			# walk backwards towards the front, until you hit :credit_count
			tokens[0..i].reverse_each.each_with_index do |t2, distance|
				if t2[2] == :credit_count
					# note: 'j' is further down the array than 'i'
					j = i - distance
					# p [j, end_index]
					
					
					foo_data_new << tokens[j..end_index]
					
					break
				end
			end
		end
		
		p foo_data_new
		
		# data = 
		# 	tokens.collect{  |start_pos, end_pos, type, captures|  type }
		# 		.join(' ')
		# 		.match(/(credit_count(.*?)year_level_category department_code)/)
		# p data.captures[0]
		
		
		# consume these tokens so no other steps can use them
		foo_data_new.flatten(1).each do |t|
			# p t
			tokens.delete t
		end
		
		# out += foo_data_new
		
		
		
		
		# unless tokens.first[1] == :department_code
		# 	# Expect that the first token is a department code
		# 	# Need to specify department codes if there are any course numbers specified
		# 	if tokens.any?{|start_pos, type, captures| type == :course_number }
		# 		raise "ERROR: first token should be a department code"
		# 	end
		# end
		
		# --- parse standard department codes. ex) 'CS 367'
		unless tokens.empty?
			most_recent_dept_code = tokens.first[1]
			
			new_data = 
				tokens.collect do |start_pos, end_pos, type, captures|
					token = captures[0]
					
					most_recent_dept_code = token if type == :department_code
					
					if type == :course_number
						[most_recent_dept_code, token].join(' ')
					end
				end
			new_data.compact!
			
			
			out += new_data 
		end
			
		
		
		
		
		
		
		puts "> #{out.inspect}"
		
		
		return out
	end
	
	
	end

end


end
