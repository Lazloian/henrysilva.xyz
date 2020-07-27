#!/bin/bash

# put post in the posts section of the given file
# Arguments 1: List file, 2: Title 3: Date, 4: Description, 5: File Name
function postList {
	# get line number of the posts section (and cut out extra stuff)
	local POSTS_NUM=$(grep -n '<!-- POSTS END -->' $1 | cut -f1 -d:)

	# write to line after latest section if post section is found
	[ -z "POSTS_NUM" ] || sed -i "${POSTS_NUM}i <article class=\"entry\">\n\
					<h3><a href=\"https://henrysilva.xyz/posts/$5.html\">$2</a> - $3</h3>\n\
					<small>$4</small>\n\
				</article>" $1
}	

# clears the posts section from the given page
# Arguments 1: Page to clear posts from
function clearPosts {
	echo "Clearing $1"

	# get line numbers of the beginning and end of the latest section
	local POSTS_BEG=$(grep -n '<!-- POSTS BEGIN -->' $1 | cut -f1 -d:)
	((POSTS_BEG++))
	local POSTS_END=$(grep -n '<!-- POSTS END -->' $1 | cut -f1 -d:)
	((POSTS_END--))

	# delete contents of latest section if there is content
	[ "$POSTS_BEG" -gt "$POSTS_END" ] || sed -i "${POSTS_BEG},${POSTS_END}d" $1
}

# stops the program with an error message
# Arguments 1: Error Message
function stopPost {
	echo "ERROR: $1"
	exit 0
}

# Creates an html post file in the given directory
# Arguements 1: Post Directory, 2: Title, 3: Date, 4: Text, 5: File Name, 6: Template Path
function makePost {
	# create path of new post file
	local POST_FILE="$1/$5.html"

	# copy post template to post path
	cp $6 $POST_FILE

	# replace page title with post title
	sed -i "s-<title>TITLE</title>-<title>$2</title>-" $POST_FILE

	# remove blank lines and add paragraphs to text
	local TEXT=$(sed '/^$/ d ; s/^/<p>/ ; s_$_</p>_' <<< $4)

	# append post to end of post file
	echo "<article class=\"post\">
<h1>$2</h1>
$TEXT
<p>- Henry Silva $3</p>
</article>
<p><a href=\"../index.html\">Back</a> To Home Page</p>
</body>" >> "$POST_FILE"
}

FILES=$(ls -t ~/posts/*.post) # All files in posts directory with .post extension

# locations of html files
INDEX=/var/www/henrysilva/index.html #./html/index.html
ALL_LIST=/var/www/henrysilva/lists/all.html #./html/lists/all.html
BOOK_LIST=/var/www/henrysilva/lists/books.html #./html/lists/books.html
PROJ_LIST=/var/www/henrysilva/lists/projects.html #./html/lists/projects.html
TEMPLATE=/var/www/henrysilva/template.html #./html/template.html

POSTS_DIR=/var/www/henrysilva/posts #./html/posts # Directory to site posts directory

POST_NUM=1 # The post number
FRONT_POSTS=5 # Number of posts to be on the front page

# clear posts from all lists
clearPosts $INDEX
clearPosts $ALL_LIST
clearPosts $BOOK_LIST
clearPosts $PROJ_LIST

# delete all files in posts directory
rm $POSTS_DIR/*

# loop through each .post file in the posts directory
for f in $FILES; do
	echo "Processing $f"
	
	# Find title, type, date, description, and text from file and stop program if they arent found
	TITLE=$(grep -m 1 'Title: ' $f  | sed 's_Title: __')
	[ -z "$TITLE" ] && stopPost "No Title"
	TYPE=$(grep -m 1 'Type: ' $f  | sed 's_Type: __')
	[ -z "$TYPE" ] && stopPost "No Type"
	DATE=$(grep -m 1 'Date: ' $f | sed 's_Date: __')
	[ -z "$DATE" ] && stopPost "No Date"
	DESC=$(grep -m 1 'Description: ' $f | sed 's_Description: __')
	[ -z "$DESC" ] && stopPost "No Description"
	TEXT=$(grep -Ev 'Title: |Type: |Date: |Description: ' $f)
	[ -z "$TEXT" ] && stopPost "No Text"
	FILE_NAME=$(basename $f | cut -d '.' -f1)
	[ -z "$FILE_NAME" ] && stopPost "No File Name"
	
	# Only post a certain number to the from page
	[ "$POST_NUM" -le "$FRONT_POSTS" ] && postList "$INDEX" "$TITLE" "$DATE" "$DESC" "$FILE_NAME"

	# Post to all posts list
	postList "$ALL_LIST" "$TITLE" "$DATE" "$DESC" "$FILE_NAME"

	# Post to list depending on type
	[ "$TYPE" = "Book" ] && postList "$BOOK_LIST" "$TITLE" "$DATE" "$DESC" "$FILE_NAME" || postList "$PROJ_LIST" "$TITLE" "$DATE" "$DESC" "$FILE_NAME"
	
	# Create post file
	makePost "$POSTS_DIR" "$TITLE" "$DATE" "$TEXT" "$FILE_NAME" "$TEMPLATE"

	# Keep track of how many posts have been processed
	((POST_NUM++))
done

# restart nginx to update website
systemctl restart nginx
