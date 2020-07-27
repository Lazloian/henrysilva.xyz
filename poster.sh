#!/bin/bash

# Removes blank lines and comments from file and outputs it to another file (Does not change source file)
# Arguments 1: Source File 2: Output File
function cleanFile {
	sed '/^$/ d ; /^#/ d' $1 > $2
}

TMP=./posting

# get input arguments. 1 is the post type, 2 is the file
TYPE=$1
POST=$2

# check if type if b or p, if not stop the program
[ "$TYPE" = "b" ] || [ "$TYPE" = "p" ] || { echo "Error: First Argument Must be b or p" ; exit 0 ; }

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

# run the updater script to update the site with the new post
ssh root@henrysilva.xyz ./scripts/updater.sh

# delete the temp file
rm $TMP
