module SummerResearch
	module Utilities

DATA_DIR = File.join(PATH_TO_ROOT, 'bin', 'data')

		class << self



# helpers
def write_to_file(relative_filepath, data)
	filepath = File.expand_path(relative_filepath, DATA_DIR)
	File.open(filepath, 'w') do |f|
		f.puts data
	end
end

def write_csv(relative_filepath, data)
	filepath = File.expand_path(relative_filepath, DATA_DIR)
	
	CSV.open(filepath, 'w') do |csv|
		data.each do |x|
			csv << x
		end
	end
end

def load_csv(relative_filepath)
	filepath = File.expand_path(relative_filepath, DATA_DIR)
	CSV.readlines(filepath)
end

def load_yaml_file(relative_filepath)
	filepath = File.expand_path(relative_filepath, DATA_DIR)
	return YAML.load_file filepath
end



end
end
end
