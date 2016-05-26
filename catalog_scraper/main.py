# use 'pip' for package management
# (very similar to 'gem' in Ruby)

import requests
from bs4 import BeautifulSoup


# write the data to the file
def dump(data, filepath):
	file = open(filepath, "w")
	file.write(str(data))
	file.close



url = "http://catalog.gmu.edu/preview_program.php?catoid=29&poid=28260&returnto=6270"
r = requests.get(url)

content = r.content

soup = BeautifulSoup(content, "html.parser")

out = soup.select("td.block_content_outer")[0]
# select returns a list of nodes, if you cast the node to a string and print it,
# it will print the subtree under that DOM node


print type(out)

# out = 

path = "./segment.html"

dump(out, path)




# parse programs of study page to get programs
# parse each of those to get the courses
# output course information and dependencies

# another pass to figure out the program requirements?
# higher-level dependecies than just what course requires what.
# Need to understand that you need a certain number of courses from particular categories.
