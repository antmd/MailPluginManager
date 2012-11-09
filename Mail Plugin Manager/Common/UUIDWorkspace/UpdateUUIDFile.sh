#!/bin/sh

#  UpdateUUIDFile.sh
#  Mail Plugin Manager
#
#  Created by Scott Little on 7/11/12.
#  Copyright (c) 2012 Little Known Software. All rights reserved.


#	Ignore if we are cleaning
if [ $ACTION = "clean" ]; then
	exit 0
fi

#	Set the locations
export MY_TOP_LEVEL="$SRCROOT/.."
export MY_COMMON_FOLDER="$SRCROOT/Common"
export MY_WORKSPACE="$MY_COMMON_FOLDER/UUIDWorkspace"
export MY_UUID_REPO_NAME="MailMessageUUIDs"
export MY_UUID_REPO="$MY_TOP_LEVEL/$MY_UUID_REPO_NAME"
export MY_REMOTE_FOLDER="$MY_TOP_LEVEL/Remote"
export MY_CURRENT_FILE="UUIDDefinitions.current.plist"
export MY_NEW_FILE="UUIDDefinitions.new.plist"
export MY_UUID_FILE="uuids.plist"

#	Go into the MailMessagesUUIDs folder and ensure that it is up-to-date
if [ ! -d "$MY_UUID_REPO" ]; then
	echo "UUID Script ERROR - The $MY_UUID_REPO_NAME submodule doesn't exist!!"
	exit 1
fi
cd "$MY_UUID_REPO"
BRANCH=`git status | grep "branch" | cut -c 13-`
IS_CLEAN=`git status | grep "nothing" | cut -c 1-17`
if [ $BRANCH != "master" ]; then
	echo "UUID Script ERROR - $MY_UUID_REPO_NAME needs to be on the master branch"
	exit 2
fi
if [[ -z $IS_CLEAN || $IS_CLEAN != "nothing to commit" ]]; then
	echo "UUID Script ERROR - $MY_UUID_REPO_NAME needs have a clean status"
	exit 3
fi
git pull


#	Run the script there that generates the UUID file
/usr/bin/osascript "ProcessMailMessageInfo.applescript" "-def"


#	Go back to where we store the current uuid copy and create hashes for both
cd "$MY_WORKSPACE"
cp "$MY_UUID_REPO/CompleteUUIDDefinitions.plist" "$MY_NEW_FILE"
if [ -f "$MY_CURRENT_FILE" ]; then
	PREV_FILE_HASH=`md5 -q $MY_CURRENT_FILE`
else
#	Set an invalid hash to ensure that they are different
	PREV_FILE_HASH="zzzzz"
fi
CURR_FILE_HASH=`md5 -q $MY_NEW_FILE`


#	If they are different, then create a copy of the new one and update the date
if [ $PREV_FILE_HASH != $CURR_FILE_HASH ]; then
#	Date Format: 2012-11-02T16:00:00Z
	MY_DATE=`date -uj +%Y-%m-%dT%H:%M:00Z`
	sed 's/<string>\[([a-zA-Z ^)]*)]<\/string>/<date>'$MY_DATE'<\/date>/g' "$MY_NEW_FILE" > "$MY_UUID_FILE"
#	Also create the previous file based on this one
	mv -f "$MY_NEW_FILE" "$MY_CURRENT_FILE"
fi

#	Move the new version with date into the Remote folder over the existing one
if [ -f "$MY_UUID_FILE" ]; then
	echo "Replacing uuid file in the Remote folder"
	mv -f "$MY_UUID_FILE" "$MY_REMOTE_FOLDER/$MY_UUID_FILE"
	exit 0
fi

echo "The uuid file was already up to date"
if [ -f "$MY_NEW_FILE" ]; then
	rm "$MY_NEW_FILE"
fi

