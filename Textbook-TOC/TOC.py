''' retrieves the table of contents. Currently only operates by passing in the isbn number ''' 

import urllib
from bs4 import BeautifulSoup as bs
import requests
import cleaner
		
# Essentially the same, but searches with isbn instead
def find_contents_isbn( isbn ):
	
	found = False
	print "Searching for ISBN: " + isbn + " currently"
	
	url_search = "http://www.worldcat.org/search?qt=worldcat_org_all&q=" + isbn 
	source_search = requests.get(url_search)
	table = bs(source_search.text).find("table" , {"class" , "table-results"})

	if(table is None):
		print "The book is not within the database"
		print ""
		return 
		
	for table_row in table.find_all("tr" , {"class" , "menuElem"}):
		link = table_row.find("a")
		url_book = link.get("href")

		url_book = "http://www.worldcat.org/" + url_book
		source_book = requests.get(url_book)
		source_soup = bs(source_book.text)
		
		## NEED TO CHECK IF THIS IS NONE! IN WHICH CASE THE CONTENTS ARE NOT PROVIDED FOR THIS BOOK, IF SO REVERT TO PREVIOUS EDITION POSSIBLY
		content_row = source_soup.find(id = "details-Nielsencontents") 
		if(content_row is None):
			content_row = source_soup.find(id = "details-contents")
			
		try:
			content = content_row.find("td")	
		except AttributeError:
			print "The OCLC database does not provide the chapter information for this book..."
			print "Checking the next entry"
			print ""
			continue
		
		content = cleaner.clean_contents(str(content))
		content = content.replace("\n" , ",")
		
		
		
		print content
		found = True
		break

	if(found):
		print "The book was found"
	else:
		print "The book was not found or there are no chapter currently"
	print ""
