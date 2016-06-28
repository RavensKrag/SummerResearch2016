#!/usr/bin/env ruby
# encoding: utf-8


require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/testtask'

require 'bundler'
Bundler.require(:default)
require 'bundler/setup'

# other libraries
require 'yaml'
require 'csv'
require 'set'
require 'open-uri'


# constants
PATH_TO_FILE = File.expand_path(File.dirname(__FILE__))

# -- file hierarchy --
		# ROOT
		# 	this directory
		# 		this file

# Must expand '..' shortcut into a proper path. But that results in a shorter string.
PATH_TO_ROOT = File.expand_path '../..', __FILE__




require 'active_record'

ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'w'))

ActiveRecord::Base.establish_connection(
	:adapter  => 'sqlite3',
	:database => 'example.db'
)










class Catalog
	def initialize(path_to_sqlite_db)
		@sqlite_db_path = path_to_sqlite_db
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
	
	def fetch
		unless Course.find_by(:dept => 'PSYC', :course_number => '260')
			data = [:dept, :course_number, :catoid, :coid].zip(%w[PSYC 260 29 306122]).to_h
			Course.create(data)
		end

		p Course.all
		p Course.all.first.course_id
	end
	
	
	
	private
	
	
	def fetch_course_listing
		
	end
	
	def fetch_details
		
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






# class Catalog < 
	
# end
