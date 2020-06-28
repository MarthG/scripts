#!/bin/bash

sourcedir="$HOME/.backup"
sharename="anotherusb"

doMonthly() {
	if ! [[ -d $monthlydir ]]; then
		echo "Target folder doesn't exist, creating '$monthlydir'"
		echo mkdir $monthlydir
	fi

	# Create a temporary directory
	#tmpdir="$(mktemp -d -t backup.XXXXXXXX)"
	if [[ -e $monthlydir/monthly.tar.gz ]]; then
		echo "$monthlydir/monthly.tar.gz exists! Updating it."

		# Copy to temp
		rsync --info=progress2 -avz "$monthlydir/monthly.tar.gz" "$sourcedir/temp.tar.gz"

		#Un-gzip
		unpigz "$sourcedir/temp.tar.gz"

		# Update tar
		tar -uvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/monthly/"

		# Re-gzip it
		pigz "$sourcedir/temp.tar"

		# Send it over to destination
		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$monthlydir/monthly.tar.gz"
	else
		echo "$monthlydir/monthly.tar.gz does not exist, gonna create it."
		# Create new tarfile
		tar -cvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/monthly/"

		# Re-gzip it
		pigz "$sourcedir/temp.tar"

		# Send it over to destination
		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$monthlydir/monthly.tar.gz"
	fi

	#echo copy /home/carlos/.backup/monthly/* $monthlydir
	echo "end of doMonthly"
}

doWeekly() {
	if ! [[ -d $weeklydir ]]; then
		echo "Target folder doesn't exist, creating '$weeklydir'"
		echo mkdir $weeklydir
	fi

	# Create a temporary directory
	#tmpdir="$(mktemp -d -t backup.XXXXXXXX)"
	if [[ -e $weeklydir/weekly.tar.gz ]]; then
		echo "$weeklydir/weekly.tar.gz exists! Updating it."

		# Copy to temp
		rsync --info=progress2 -avz "$weeklydir/weekly.tar.gz" "$sourcedir/temp.tar.gz"

		#Un-gzip
		unpigz "$sourcedir/temp.tar.gz"

		# Update tar
		tar -uvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/weekly/"

		# Re-gzip it
		pigz "$sourcedir/temp.tar"

		# Send it over to destination
		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$weeklydir/weekly.tar.gz"
	else
		echo "$weeklydir/weekly.tar.gz does not exist, gonna create it."
		# Create new tarfile
		tar -cvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/weekly/"

		# Re-gzip it
		pigz "$sourcedir/temp.tar"

		# Send it over to destination
		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$weeklydir/weekly.tar.gz"
	fi

	#echo copy /home/carlos/.backup/weekly/* $weeklydir
	echo "end of doWeekly"
}

reqChecks() {
	mntpoint="$(mount | grep "$sharename" | cut -d" " -f3)"
	echo "Detected mount point at $mntpoint for search-term '$sharename'"

	weeklydir="$mntpoint/.backup/$(hostname)-weekly"
	monthlydir="$mntpoint/.backup/$(hostname)-monthly"

	if ! [[ -d "$sourcedir/weekly" ]]; then echo "$sourcedir/weekly doesn't exist. Please create it or edit the script to point to the proper folder."; fi
	if ! [[ -d "$sourcedir/monthly" ]]; then echo "$sourcedir/monthly doesn't exist. Please create it or edit the script to point to the proper folder."; fi

	if ! [[ -d "$weeklydir" ]]; then echo "Creating $weeklydir"; mkdir -p $weeklydir; fi
	if ! [[ -d "$monthlydir" ]]; then echo "Creating $monthlydir"; mkdir -p $monthlydir; fi

	touch $weeklydir/perms
	# If touch has return-code 1 it means we can't write, for whatever reason-- we'll assume it's permissions
	if [[ $? -eq 1 ]]; then echo "Hey! The user running the script ($(whoami)) has no permissions to access $weeklydir!"; else rm $weeklydir/perms; fi
	touch $monthlydir/perms
	if [[ $? -eq 1 ]]; then echo "Hey! The user running the script ($(whoami)) has no permissions to access $monthlydir!"; else rm $monthlydir/perms; fi
}

if [[ -z $(mount | grep "$sharename") ]]; then
	echo "Network share not found... Please mount it with FUSE and try again."
	exit
else
	echo "Starting up"
	reqChecks
fi

if [[ $1 == "monthly" || $1 == "m" ]]; then
	doMonthly
	if [[ -e "$sourcedir/temp.tar" ]]; then rm "$sourcedir/temp.tar"; fi
	if [[ -e "$sourcedir/temp.tar.gz" ]]; then rm "$sourcedir/temp.tar.gz"; fi
elif [[ $1 == "weekly" || $1 == "w" ]]; then
	doWeekly
	if [[ -e "$sourcedir/temp.tar" ]]; then rm "$sourcedir/temp.tar"; fi
	if [[ -e "$sourcedir/temp.tar.gz" ]]; then rm "$sourcedir/temp.tar.gz"; fi
fi
