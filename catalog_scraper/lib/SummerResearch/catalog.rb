module SummerResearch


class Catalog
	def initialize
		
	end
	
	def setup
		ActiveRecord::Schema.define do
			unless ActiveRecord::Base.connection.tables.include? 'courses'
				create_table :courses do |table|
					table.column :dept,          :string
					table.column :course_number, :string
					table.column :catoid,        :string
					table.column :coid,          :string
				end
			end
		end
	end
	
	# fetch list of all avaiable courses from the catalog
	# (currently only gets the first page of results from each deparment, but that should probably be up to 499 for most, if not all, deparments. Should be good enough to analyze undegrad programs.)
	# 
	# postcondition: populate @storage
	def fetch
		puts "fetching data..."
		# departments      = SummerResearch.all_department_codes
		# courses_per_dept = departments.collect{  |dept| SummerResearch.search_by_department(dept) }
		# 									# (no specific data. just URLs, link types, etc)
		
		# data = departments.zip(courses_per_dept).to_h
		# # department => [CatalogLink]
		
		
		departments = SummerResearch.all_department_codes()
		departments.each do |department|
			SummerResearch.search_by_department(department).each do |catalog_link|
				dept, course_number = parse_course_id(catalog_link.id)
				
				next if Course.find_by(:dept => dept, :course_number => course_number)
				
				catoid, coid = parse_url(catalog_link.url)
				
				Course.create(
					:dept          => dept,
					:course_number => course_number,
					:catoid        => catoid,
					:coid          => coid
				)
			end
			
			sleep(0.5)
		end
		
		
		return self
	end
	
	# precondition: run #fetch to populate @storage
	def download_course_info(course_id)
		if course_id.is_a? SummerResearch::CatalogLink
			raise "ERROR: argument should be a course id, not a CatalogLink object"
		end
		
		
		# TODO: consider using a real database for storage, so you don't have to worry about effeciency of searching for records.
		
		# TODO: switch to SQL  ASAP
		
		dept_code, course_number = course_id.split(' ')
		
		department_listing = @storage[dept_code]
		
		unless department_listing
			raise "ERROR: no department found. Looking for '#{dept_code}' (#{course_id})"
		end
		
		course_link = department_listing.find{  |cat_link| cat_link.id == course_id }
		
		raise "ERROR: Department found, but not the course. Looking for '#{course_id}'" unless course_link
		
		# course_link = department_listing.bsearch{  |cat_link| cat_link.id.split(' ').last >= course_number }
		# TODO: profile to see if it is worth it to use bsearch
		
		info = SummerResearch::CourseInfo.new(course_link).fetch
		
		return info
	end
	
	
	private
	
	# TODO: consider case of Mason Core classes
	def parse_course_id(course_id)
		dept_code, course_number = course_id.split(' ')
		
		return dept_code, course_number
	end
	
	def parse_url(url)
		# example:  http://catalog.gmu.edu/preview_course.php?catoid=29&coid=305044&print
		regex = /preview_course.php\?catoid=(\d+)&coid=(\d+)/
		match_data = url.match(regex)
		catoid = match_data[1]
		coid   = match_data[2]
		
		return catoid, coid
	end
	
	
	
	
	
	

	# backs to SQL (relational logic)
	class Course < ActiveRecord::Base
		# self.primary_keys = :dept, :course_number
		
		def course_id
			[self.dept, self.course_number].join(' ')
		end
		
		
		def find_by_course_id(course_id)
			dept, number = dept_and_number(course_id)
			return self.class.find_by(:dept => dept, :course_number => number)
		end
	end
	private_constant :Course
	
	
	
	# backs to Mongo (document store)
	class CourseDetails
		
	end
	private_constant :CourseDetails
end



end
