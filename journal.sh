#!/bin/bash
jndir="/mnt/b/journal"
jndatefmt="%d-%b-%Y"
jnfmt="$(date +$jndatefmt)"
editor="/usr/bin/vi"


listFiles() {
	if ! [[ -d $jndir ]]; then
		read -p "Journal directory doesn't exist. There are no journal files. Create [$jndir]? " ans
		case $ans in
		        [yY] | [yY][Ee][Ss]) mkdir $jndir || echo "Not enough permissions to create [$jndir]";;
		        [nN] | [n|N][O|o]) echo "Okay. Exiting.";exit 1;;
		        *) echo "Invalid input";;
		esac
		echo "Created the directory. There are no journal files."
		exit 0
	else
		jnls="$(ls $jndir)"
		if ! [[ $? == 0 ]]; then echo "There was an error getting the file list. No perms?"; exit -1; fi
		if [[ -z $jnls ]]; then
			echo "There are no journal files."
			exit 0
		fi
		ls $jndir	

	fi
}

editToday() {
	jntoday="$jndir/$jnfmt"
	if ! [[ -e $jntoday ]]; then
		echo "Today's journal doesn't exist. Creating it."
		touch $jntoday
		if [[ $? == 1 ]]; then echo "No permissions on [$jndir]."; exit -1; fi
	fi
	$editor $jntoday
}

doHelp() {
	echo "stub. help is \'-l\' to list files, nothing or \'-e\' to edit today's file."
}

case $1 in
		-l | ls | l | list) listFiles;;
		-h | -? | --help | --?) doHelp;;
		-e | edit | e | --edit) editToday;;
		*) doHelp;;
esac

