#!/bin/bash

# Removes blank lines and comments from file and outputs it to another file (Does not change source file)
# Arguments 1: Source File 2: Output File
function cleanFile {
	sed '/^$/ d ; /^#/ d' $1 > $2
}

# Uploads a new post to the website using the content from the input file
# Arguments 1: Post Type 2: Input File
function uploadPost {

	TMP=./posting

	# get input arguments. 1 is the post type, 2 is the file
	TYPE=$1
	POST=$2

	# check if type if b or p, if not stop the program
	[ "$TYPE" = "b" ] || [ "$TYPE" = "p" ] || { echo "Error: Post Type Must be b or p" ; exit 0 ; }

	# check if the file given is a valid file
	[ -f "$POST" ] || { echo "Error: File Invalid" ; exit 0 ; }

	# remove any blank lines or comments and output text to a temp file
	cleanFile $POST $TMP

	# get title from first line and description from second line
	TITLE=$(sed '1q;d' $TMP)
	DESC=$(sed '2q;d' $TMP)

	# set type to full string type based on the argument
	[ "$TYPE" = "b" ] && TYPE="Book" || TYPE="Project"

	# get the current date
	DATE=$(date +'%m/%d/%Y')

	# get the rest of the text from the source file
	TEXT=$(tail -n +3 $TMP)

	# clear temp file and insert post in correct format
	rm $TMP
	printf "Title: $TITLE\nType: $TYPE\nDate: $DATE\nDescription: $DESC\n$TEXT" >> $TMP

	# get the name of the source file
	FILE_NAME=$(basename $POST | cut -d '.' -f1)

	# copy the temp file to the server
	scp $TMP "root@henrysilva.xyz:~/posts/$FILE_NAME.post"

	# delete the temp file
	rm $TMP
}

# Removes post from website
# Arguments 1: Name of Post File
function removePost {
	# try to remove the post from the server
	ssh root@henrysilva.xyz rm "posts/$1.post" && echo "Post Removed" || echo "Error: Post Not Found"
}

# Lists all the file names of all the posts on the website
# No Arguments
function listPosts {
	ssh root@henrysilva.xyz ls posts | sed 's/\.post$//g'
}

# Updates the website
# No Arguments
function update {
	ssh root@henrysilva.xyz ./scripts/updater.sh
}

# Prints the help text
# No Arguments
function printHelp {
	echo "To Post a File to the Website Run: p followed by the post type (p or b) and then the file to post
To List Posts on the Server Run: l
To Remove a Post on the Server Run: r followed by the file name of the post
To Update the Website Run: u"
}

# get the run option
OP=$1

# run function based on option, if none match output an error
{ [ "$OP" = "p" ] && uploadPost $2 $3 ; } || { [ "$OP" = "l" ] && listPosts ; } || { [ "$OP" = "r" ] && removePost $2 ; } || { [ "$OP" = "u" ] && update ; } || { [ "$OP" = "h" ] && printHelp ; } || echo "Error: Run Option Must be 'p', 'l', 'r', or 'u'
For Help, use Run Option 'h'"

echo -e "\nDone"



















