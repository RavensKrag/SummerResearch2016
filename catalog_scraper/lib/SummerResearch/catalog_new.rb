class Catalog
	def initialize(database_filepath, log_filepath='database.log')		
		SQLite.setup(database_filepath, log_filepath)
		
		@mongo_ip      = "127.0.0.1"
		@mongo_port    = "12345"
		@mongo_address = [@mongo_ip, @mongo_port].join(':')
		@mongo = Mongo::Client.new([ @mongo_address ], :database => 'mydb')
	end
	
	def setup
		ActiveRecord::Schema.define do
			# NOTE: this schema definition may have problems with mulitple DBs? Not totally sure
			unless SQLite.connection.tables.include? 'courses'
				create_table :courses do |table|
					table.column :dept,          :string
					table.column :course_number, :string
					table.column :catoid,        :string
					table.column :coid,          :string
				end
			end
			
			unless SQLite.connection.tables.include? 'catalog_years'
				create_table :catalog_years do |table|
					table.column :catoid,         :string
					table.column :courses_navoid, :string
					table.column :year_range,     :string
				end
			end
		end
	end
	
	def fetch_course_listing
		# go to the main catalog page
		# and figure out what catalog years are avaiable
		url = "http://catalog.gmu.edu"
		
		xml = Nokogiri::HTML(open(url))
		
		# SummerResearch::Utilities.write_to_file("./catalog_temp.html", xml)
		
		node = xml.xpath('//form[@name="select_catalog"]')
			SummerResearch::Utilities.write_to_file("./catalog_temp.html", node)
		
		                                             # catoid number, date range
		                                             # ["29",        "2016-2017"]
		data = node.first.css('option').collect{  |x|  [x['value'],    x.inner_text.split.first]  }
		
		data.each do |catoid, year_range_string|
			next if CatalogYear.find_by(:catoid => catoid)
			
			CatalogYear.create(
				:catoid         => catoid,
				# :courses_navoid => ,
				:year_range     => year_range_string
			)
		end
		
		
		
		
		
		# For each available catalog year, navigate to the Course search page
		# (Set 'courses_navoid' field for each CatalogYear record. Enables link to course search)
		CatalogYear.all.each do |record|
			next unless record.courses_navoid.nil?
			
			# p record
			url = "http://catalog.gmu.edu/index.php?catoid=#{record.catoid}"
			
			xml = Nokogiri::HTML(open(url))
			
			relative_link_to_course_search = xml.xpath('//a[text()="Courses"]').first['href']
			
			p relative_link_to_course_search
			
			regex = /navoid=(\d+)/
			matchdata = relative_link_to_course_search.match(regex)
			
			# p matchdata[1]
			
			record.update(:courses_navoid => matchdata[1])
			# record.courses_navoid = matchdata[1]
			# record.save
		end
		
		
		
		
		# useful test of a catalog year that is not the current year, and a department that failed to download before
		# year = CatalogYear.find_by(:year_range => "2015-2016")
		# p search_by_department(year.catoid, year.courses_navoid, "CTCH")
		
		
		
		
		
		# OK this is way too much data.
		# As expected, need to restrict data to only relevant departments, if you want to go back multiple years.
		# Trying to go back 8 years, so try to cull down to 1/8 of the departments in order to download in a reasonable time.
		
		
		# CatalogYear.all.each do |record|
		# 	puts "#{record.year_range} Catalog Year"
			
		# 	# --- For each catalog year, find the list of department IDs for that year
		# 	url = "http://catalog.gmu.edu/content.php?catoid=#{record.catoid}&navoid=#{record.courses_navoid}"
		# 	p url
			
		# 	dept_codes = all_department_codes(url)
		# 	p dept_codes
		# end
		
		
		
		# really want to split this up into two separate steps, so pipeline is smoother
		
		# catalog year -> department codes
		# year, department codes -> list of courses available in that year
		
		# (keep having to re-downlod list of dept codes per year, even if you already have the list of all the coursese available in that year.)
		
		
		
		
		# Restrict departments to a useful subset.
		# Should include all deparments necessary to evaulate CS EE IT Psyc and Bio degrees.
		restricted_set = (%w[BIOL CHEM MATH CS SWE IT PSYC CDS ASTR GEOL PHYS GGS NEUR CRIM PHIL ENGH STAT ECE COMM ECON BENG MBUS HAP OR SEOR OM SYST EVPP] + ["Mason Core"]).to_set
		
		CatalogYear.all.each do |record|
			puts "#{record.year_range} Catalog Year"
			
			# --- For each catalog year, find the list of department IDs for that year
			url = "http://catalog.gmu.edu/content.php?catoid=#{record.catoid}&navoid=#{record.courses_navoid}"
			p url
			
			dept_codes = all_department_codes(url)
			# p dept_codes
			dept_codes.select!{ |x| restricted_set.include? x } # must be in the list, and the set
			
			
			# --- Search for all avaiable courses in each department
			dept_codes.each do |department|
				# skip this whole department if you've seen it before,
				# within the specificed catalog year
				next if Course.find_by(:dept => department, :catoid => record.catoid)
				
				all_links = search_by_department(record.catoid, record.courses_navoid, department)
				all_links.each do |catalog_link|
					dept, course_number = Catalog.parse_course_id(catalog_link.id)
					
					coid = Catalog.coid_from_url(catalog_link.url)
					
					Course.create(
						:dept          => dept,
						:course_number => course_number,
						:catoid        => record.catoid,
						:coid          => coid
					)
				end
				
				sleep(0.5)
			end
			
		end
		
		
		
		
		
		# regex = 
		# relative_link_to_course_search
		
		
		
		
		# Now that you've populated the database with all the courses that you think you will need,
		# you can get information on particulars as needed.
		# DO NOT DO THIS ALL IN ONE STEP
		# Only get documents when explictly requested, and then cache them in a Mongo database.
		# 
		# Use the SQL database to figure out "given a name like CS 101, what is the catalog url?"
		
		
		# TODO: figure out what data actually needs to be passed over to CourseInfo to fetch data, and just pass that?
			# catalog_link = CatalogLink.new()
			# info = CourseInfo.new(catalog_link).fetch
		# TODO: move this into another method or something. it is not needed here.
	end
	
	
	# get info on a particular course.
	# assume that if no year is specified, the most recent information is desired
	# 
	# May fetch data over the network as needed.
	# Assuming that catalog data never changes once the catalog has been published.
	def course_info(course_id, catalog_year=:most_recent)
		if catalog_year == :most_recent
			
			
			# puts "Select a year"
			# p CatalogYear.find_by(:year_range => '2014-2015').courses
			
			
			# puts "main query"
			dept, course_number = Catalog.parse_course_id(course_id)
			
			
			# symbols = CatalogYear.methods.grep(/name/)
			# results = symbols.collect{|sym| CatalogYear.send(sym)  }
			# p symbols.zip(results).to_h
			# p symbols
			
			# p CatalogYear.methods
			# p CatalogYear.name
			# p CatalogYear.model_name
			
			
			
			
			most_recent_course_record = 
				Course.where(:dept => dept, :course_number => course_number)
				      .joins(:catalog_year)
				      .order("year_range DESC").first
			# course_list = Course.where(:dept => dept, :course_number => course_number)
			# p course_list.joins(:catalog_year).order("year_range DESC").first
			
			p most_recent_course_record
			# course_list.each do |course|
			# 	p course.catalog_year.year_range
			# end
			
			
			
			
			
			
			# ==================
			# basically manually performing a JOIN with Mongo data at this point
			# (need to downlad the data if necessary)
			# ==================
			
			record = most_recent_course_record
			url = record.url
			catalog_year = record.catalog_year.year_range
			
			
			# check if the document is in MongoDB
			document = 
				@mongo[:course_info].find(
					:course_id => record.course_id, :catalog_year => catalog_year
				)
				.limit(1)
				.first
			
			
			info = 
				if document.nil?
					# Document not found. Fetch data and add it to DB.
					# Return the original CourseInfo object, which is still in memory.
					info = CourseInfo.new(record.dept, record.course_number, catalog_year, url)
					info.fetch
					
					# puts info.to_h
					
					# p @mongo[:course_info]
					@mongo[:course_info].insert_one(info.to_h)
					
					
					info # pseudo-return for block
				else
					# Document was in MongoDB. Turn it back into a CourseInfo object.
					# p document.class # => BSON::Document
					
					CourseInfo.load(document)
				end
			
			return info
		else
			raise "ERROR: NOT IMPLEMENTED YET"
		end
	end
	
	# expose the database to the block.
	# should automatically handle "normalization" of switching between SQL and Mongo
	def query(&block)
		
	end
	
	
	def activerecord_query(&block)
		block.call(Course, CatalogYear)
	end
	
	def mongo_query(namespace, &block)
		block.call @mongo[namespace]
	end
	
	def course_details_mongo(&block)
		block.call @mongo[:course_info]
	end
	
	
	
	
	
	private
	
	
	# return all department codes from the Courses search page in the catalog
	# (operates on one page from one catalog year)
	def all_department_codes(url)
		xml = Nokogiri::HTML(open(url))
		
		#course_search > table > tbody > tr:nth-child(4) > td:nth-child(1) > select
		segment = xml.css('#course_search table tr:nth-child(4) > td:nth-child(1) > select > option')
			# Utilities.write_to_file("./department_codes_fragment.html", segment)
		
		departments = segment.collect{  |option_node|  option_node["value"]  } 
		departments.shift # remove the first one, which is just -1, the default nonsense value
		
		return departments
	end
	
	# get a list of classes using the catalog search
	# ex) "BIOL", "CS", etc
	# returns a list of CatalogLink objects
	# 
	# Sometimes fails to get the list, but will automatically retry as many times as necessary.
	def search_by_department(catoid, navoid, dept_code)
		# use this url to search for courses
		# may return mulitple pages of results, but should be pretty clear
		
		# TODO: modify url to use COURSE_SEARCH_BASE_URL constant (reorder url args)
		url = "http://catalog.gmu.edu/content.php?filter%5B27%5D=#{dept_code}&filter%5B29%5D=&filter%5Bcourse_type%5D=-1&filter%5Bkeyword%5D=&filter%5B32%5D=1&filter%5Bcpage%5D=1&cur_cat_oid=#{catoid}&expand=&navoid=#{navoid}&search_database=Filter#acalog_template_course_filter"
		
		
		
		xml = Nokogiri::HTML(open(url))
		
		puts "searching for classes under: #{dept_code} ..."
		
		node = xml.css('td.block_content_outer table')[3]
			# SummerResearch::Utilities.write_to_file("./search.html", xml) if node.nil?
		# NOTE: sometimes fails to find courses.
		# just retry the request again, and you should be able to get it.
		while node.nil?
			puts "nope. wait a sec..."
			sleep(3.0) # wait a bit before retrying
			puts "retrying #{dept_code}..."
			
			xml = Nokogiri::HTML(open(url))
			node = xml.css('td.block_content_outer table')[3]
		end
			
		
		# NOTE: results are paginated. Should get info from ALL pages, not just the first one.
		
		tr_list = node.css('tr')[2..-1]
		
		# tr_list.each{|x| puts x.class }
		return tr_list.collect{  |x| SummerResearch.get_all_weird_link_urls(x)  }.flatten
		
		
		
		
		# As noted in notes on how the Catalog URL works:
		# corresponding pages in different versions of the catalog DO NOT have analogous numbers.
		# This makes scraping the catalog considerably more tedious.
		
		#[29, 27, 25] # etc
		# http://catalog.gmu.edu/index.php?catoid=25   (base page)
		# in the left sidebar, there is a link for "Courses"
		# href: http://catalog.gmu.edu/content.php?catoid=25&navoid=4962
		# need to extract that navoid value
	end
	
	
	class << self
		# TODO: consider case of Mason Core classes
		def parse_course_id(course_id)
			dept_code     = nil
			course_number = nil
			
			if course_id.include? "Mason Core"
				dept_code = "Mason Core"
				
				matchdata = course_id.match(/Mason Core (.*)/)
				
				course_number = 
					if matchdata
						matchdata[1]
					else
						nil
					end
				
				# don't want it to trip up on just getting "Mason Core"
				# but not sure what to do, because this isn't really course?
			else
				dept_code, course_number = course_id.split(' ')
				course_number = course_number
			end
			
			return dept_code, course_number
		end
		
		# url => catoid, coid
		def coid_from_url(url)
			# example:  http://catalog.gmu.edu/preview_course.php?catoid=29&coid=305044&print
			regex = /preview_course.php\?catoid=(\d+)&coid=(\d+)/
			match_data = url.match(regex)
			catoid = match_data[1]
			coid   = match_data[2]
			
			return coid
		end
		
		# catoid, coid => url
		def course_description_url(catoid, coid)
			return "http://catalog.gmu.edu/preview_course.php?catoid=#{catoid}&coid=#{coid}"
		end
	end
	
	
	
	
	
	
	
	
	
	class SQLite < ActiveRecord::Base
		class << self
			def setup(database_filepath, log_filepath)
				self.logger = Logger.new(File.open(log_filepath, 'w'))
				
				self.establish_connection(
					:adapter  => 'sqlite3',
					:database => database_filepath
					# :database => ':memory:'
				)
				
				warn("Warning: ActiveRecord connection established by #{self} during #initialize")
				# want to let people know what's happening, because has implications
				# for using Catalog inside of other systems.
			end
		end
		
		self.abstract_class = true
	end
	private_constant :SQLite
	
	# backs to SQL (relational logic)
	class Course < SQLite
		# self.primary_keys = :dept, :course_number
		belongs_to :catalog_year, :foreign_key => 'catoid'
		
		def course_id
			[self.dept, self.course_number].join(' ')
		end
		
		
		def find_by_course_id(course_id)
			dept, number = dept_and_number(course_id)
			return self.class.find_by(:dept => dept, :course_number => number)
		end
		
		def url
			return Catalog.course_description_url(self.catoid, self.coid)
		end
	end
	private_constant :Course
	
	# backs to SQL (relational logic)
	class CatalogYear < SQLite
		# TODO: link to Course with foreign key constraint (catoid)
		self.primary_keys = :catoid
		
		has_many :courses, :foreign_key => 'catoid'
	end
	private_constant :CatalogYear
	
	
	
	
	
	
	
	
	
	
	# backs to Mongo (document store)
	class CourseDetails
		
	end
	private_constant :CourseDetails
end
