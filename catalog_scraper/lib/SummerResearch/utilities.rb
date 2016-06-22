module SummerResearch
	module Utilities
		class << self


# helpers
def write_to_file(filepath, data)
	File.open(filepath, 'w') do |f|
		f.puts data
	end
end


def write_csv(filepath, data)
	CSV.open(filepath, 'w') do |csv|
		data.each do |x|
			csv << x
		end
	end
end

def load_csv(filepath)
	CSV.read_lines(filepath)
end

def load_yaml_file(filepath)
	return YAML.load_file filepath
end



end
end
end
