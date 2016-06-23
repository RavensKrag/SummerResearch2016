module SummerResearch


class Catalog
	def initialize
		@storage = nil
	end
	
	class << self
		def load(filepath)
			storage = YAML.load_file(filepath + '.yaml')
			
			catalog = Catalog.new
			catalog.instance_eval do
				@storage = storage
			end
			
			return catalog
		end
	end
	
	def dump(filepath)
		File.open(filepath + '.yaml', 'w') do |f|
			f.puts @storage.to_yaml
		end
	end
	
	
	
	# fetch list of all avaiable courses from the catalog
	# (currently only gets the first page of results from each deparment, but that should probably be up to 499 for most, if not all, deparments. Should be good enough to analyze undegrad programs.)
	# 
	# postcondition: populate @storage
	def fetch
		departments      = SummerResearch.all_department_codes
		courses_per_dept = departments.collect{  |dept| SummerResearch.search_by_department(dept) }
											# (no specific data. just URLs, link types, etc)
		
		@storage = departments.zip(courses_per_dept).to_h
		# department => [CatalogLink]
		
		return self
	end
	
	# precondition: run #fetch to populate @storage
	def download_course_info(course_id)
		# TODO: consider using a real database for storage, so you don't have to worry about effeciency of searching for records.
		
		dept_code, course_number = course_id.split(' ')
		
		department_listing = @storage[dept_code]
		course_link = department_listing.find{  |cat_link| cat_link.id == course_id }
		# course_link = department_listing.bsearch{  |cat_link| cat_link.id.split(' ').last >= course_number }
		# TODO: profile to see if it is worth it to use bsearch
		
		info = SummerResearch::CourseInfo.new(course_link).fetch
		
		return info
	end
end



end
