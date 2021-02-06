#!/bin/bash

# path to saved commands
DATA=~/.shortcuts.data

# create DATA if doesnt exist
if [[ ! -f $DATA ]] ; then
	touch $DATA
fi

# set flags
while getopts 'haldD' flag; do
	case "$1" in
		-h|--help)
			echo && echo shortcuts [OPTION] [COMMAND] [CATEGORY] [DESCRIPTION] && echo
			printf "%-20s" "-a --add" "add command to shortcuts data file" && echo
			printf "%-20s" "-l --list" "list categories. Optionally provide a [CATEGORY] to list its commands and descriptions" && echo
			printf "%-20s" "-d --delete" "remove command from specified category" && echo
			printf "%-20s" "-D --delete-category" "remove all entries for provided category (will warn)" && echo
			;;
		-a|--add)
			shift
			ADD_FLAG='true'
			;;
		-l|--list)
			shift
			LIST_FLAG='true'
			;;
		-d|--delete)
			shift
			DELETE_FLAG='true'
			;;
		-D|--delete-category)
			shift
			DELETE_CATEGORY_FLAG='true'
	esac
done

deleteCategoryPrompt() {
	echo && read -p "This will remove all entries for the \"$1\" category. Are you sure? (Y/N): " PROMPT
}

deleteCategoryConfirmationPrompt() {
	echo && read -p "Please Confirm: All entries for \"$1\" will be permanently deleted. (FINAL WARNING!) (Y/N): " PROMPT
}

deleteCommandFromCategoryPrompt() {
	echo && read -p "This will remove the \"$1\" entry from the \"$2\" category. Are you sure? (Y/N): " PROMPT
	if [[ $PROMPT = 'N' ]] || [[ $PROMPT = 'n' ]] ; then
		echo Aborting... && exit 1
	elif [[ $PROMPT = 'y' ]] || [[ $PROMPT = 'Y' ]] ; then
		RETURN='true'
		echo removing entry \"$1\" from category \"$2\"... && return 0
	else
		echo Invalid input.
	fi
}

function checkIfCommandExists() {
	cat $DATA | while read line ; do
		read -a lineArray <<< $line
		if [[ ${lineArray[0]} == $1 ]] ; then
	       		echo error: $1 already exists && exit 1
	       	fi
	done
}

function printCategories() {
	CATEGORIES=() && BOOLEAN="false"
	echo CATEGORIES: && echo
	cat $DATA | ( 
		while read line ; do
			read -a lineArray <<< $line
			for x in ${CATEGORIES[@]}; do
				if [[ $x == ${lineArray[1]} ]]; then
					BOOLEAN="true"
				fi	
			done
			if [[ $BOOLEAN != "true" ]]; then
				CATEGORIES+=( ${lineArray[1]} )
			fi
		BOOLEAN="false"
		done
		for CATEGORY in ${CATEGORIES[@]}; do
			echo $CATEGORY
		done
       	)
}

function printCommandListByCategory() {
	cat $DATA | while read line ; do
		read -a lineArray <<< $line
		if [[ ${lineArray[1]} == $1 ]] ; then
			VAL=`grep -oP '(?<=").*?(?=")' <<< $line`
			echo '-----' && printf "%-20s" "${lineArray[0]}" "$VAL" && echo
		fi	
	done && echo '-----'
}

function deleteCategoryNegativePrompt() {
	if [[ $1 = 'N' ]] || [[ $1 = 'n' ]] ; then
		echo Aborting... && exit 1
	else 
		echo Invalid input!
	fi
}

function deleteCategoryPositivePrompt() {
	deleteCategoryPrompt $1
	if [[ $PROMPT = 'Y' ]] || [[ $PROMPT = 'y' ]] ; then
		deleteCategoryConfirmationPrompt $1
		if [[ $PROMPT = 'Y' ]] || [[ $PROMPT = 'y' ]] ; then
			echo && echo removing \"$1\" category \& entries... && echo && return 0
		fi
	fi
}

function deleteCommandFromCategory() {
	COMMAND=$1 && CATEGORY=$2 && COUNT=0
	cat $DATA | ( while read line ; do
		read -a lineArray <<< $line
		((COUNT+=1)) && if [[ ${lineArray[0]} == $COMMAND ]] && [[ ${lineArray[1]} == $CATEGORY ]]; then
			COUNT+=d && sed -i.bak -e "$COUNT" $DATA
		fi
	done )
}

function deleteCategory {
	CATEGORY_LINE_NUMS=$(awk -F' ' '{ print NR, $2 }' $DATA | grep $1 | grep -o -E '[0-9]+')
	SED_STRING=""
	for lineNumber in ${CATEGORY_LINE_NUMS[@]}; do
		SED_STRING+=${lineNumber}d\;
	done
	sed -i.bak -e "$SED_STRING" $DATA
}

# add command to $DATA
if [[ $ADD_FLAG = "true" ]]; then
	checkIfCommandExists $1 
	if [[ $? -ne 1 ]] ; then
		echo $1 $2 '"'$3'"' >> $DATA
		echo $1 && echo $2 && echo '"'$3'"'
	fi
fi

# list commands by category
if [[ $LIST_FLAG = 'true' ]] ; then
	if [[ $# -eq 0 ]] ; then
		printCategories
	else
		printCommandListByCategory $1
	fi
fi

# delete command from category
if [[ $DELETE_FLAG = 'true' ]] ; then
	while true ; do
		deleteCommandFromCategoryPrompt $1 $2
		if [[ $? -eq 0 ]]; then
			deleteCommandFromCategory $1 $2
			exit 1
		fi
	done
fi

# delete all entries for the provided category
if [[ $DELETE_CATEGORY_FLAG = 'true' ]] ; then
	while true ; do
		deleteCategoryPositivePrompt $1
		if [[ $? -eq 0 ]] ; then
			deleteCategory $1
			echo Complete. && exit 1
		fi
		deleteCategoryNegativePrompt $PROMPT
	done	
fi
