''' The test driver. Passes in the isbn numbers and retrieves the table of contents if world cat has the information '''

import cleaner
import re
import TOC


# These test cases are with the textbook title, lets try isbn now
# The problem with this one is a lack of chapters being provided....
# TOC.find_contents("Data Structures & Problem Solving Using Java")

# TOC.find_contents("Ethics for the Information Age")
# TOC.find_contents("The C Programming Language")
# TOC.find_contents("Ethics for the Information Age")
# TOC.find_contents("Database Systems - An Application-Oriented Approach, Introductory Version")
# TOC.find_contents("Oracle 10g Programming: A Primer")
# TOC.find_contents("The C Programming Language")

run = False

if(run):
	isbn_list =  ["978-0321228383" , 
	"978-0131103627" , "978-0321541406" , "978-0130654878" , "978-1118129388" , " 978-0321489845", "9780073398174","9781305075450" , "9780078034770", "9780134261683",
	"978-0538745840", "9781285170626", "978-0470128725", "860-1419506989" , "000-0387008934" , "978-0136085928" , "978-1848829343" , "978-1133593607" , "978-0131653160", "978-0321295354" 
	, "978-0321321367"]
	
	for test in isbn_list:
		TOC.find_contents_isbn(test)
else:
	
