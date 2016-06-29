module SummerResearch


class << self

def foobar(catalog_db_data, course_id)
	record = catalog_db_data.select{  |data| data[0..1].join(' ') == course_id  }.first
	
	dept, course_number, catoid, coid = record
	
	return {
		:catoid => catoid,
		:coid => coid
	}
end



end
end
