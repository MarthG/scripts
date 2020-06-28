#!/bin/bash

echo ".backup.sh (ALT)"

sourcedir="$HOME/.backup"
sharename="anotherusb"

eecho() {
echo "[OUT] -- $1"
}

# Code left here for reference's sake-- removal due soon
doMonthly() {
# 	if ! [[ -d $monthlydir ]]; then
# 		eecho "Target folder doesn't exist, creating '$monthlydir'"
# 		eecho mkdir $monthlydir
# 	fi
# 
# 	# Create a temporary directory
# 	#tmpdir="$(mktemp -d -t backup.XXXXXXXX)"
# 	if [[ -e $monthlydir/monthly.tar.gz ]]; then
# 		eecho "$monthlydir/monthly.tar.gz exists! Updating it."
# 
# 		# Copy to temp
# 		rsync --info=progress2 -avz "$monthlydir/monthly.tar.gz" "$sourcedir/temp.tar.gz"
# 
# 		#Un-gzip
# 		unpigz "$sourcedir/temp.tar.gz"
# 
# 		# Update tar
# 		tar -uvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/monthly/"
# 
# 		# Re-gzip it
# 		pigz "$sourcedir/temp.tar"
# 
# 		# Send it over to destination
# 		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$monthlydir/monthly.tar.gz"
# 	else
# 		eecho "$monthlydir/monthly.tar.gz does not exist, gonna create it."
# 		# Create new tarfile
# 		tar -cvf "$sourcedir/temp.tar" --totals --checkpoint=.1000 "$sourcedir/monthly/"
# 
# 		# Re-gzip it
# 		pigz "$sourcedir/temp.tar"
# 
# 		# Send it over to destination
# 		rsync --info=progress2 -avz "$sourcedir/temp.tar.gz" "$monthlydir/monthly.tar.gz"
# 	fi
# 
# 	#eecho copy /home/carlos/.backup/monthly/* $monthlydir
	eecho "STUB-- end of doMonthly; old and broken code"
}

doWeekly() {
	copymonth="$(cat $weeklydir/month)">/dev/null 2>&1

	if [[ $copymonth -eq $monthnum && -e $weeklydir/week-$monthnum.tar ]]; then
		eecho "Nothing to do-- backup already done!"
		exit 1
	fi

	if [[ $? == "1" ]] || ! [[ -e $weeklydir/month ]] || [[ -z $copymonth ]]; then
		# handle non-existing tracker
		eecho "Non-existing or empty tracking file, creating one and putting aside existing data. We'll archive this week anyways."
		if [[ $(ls $weeklydir/*.tar.gz | wc -l) -gt 0 ]]; then
			eecho "There were previous files. Moving them out to '$weeklydir/..'"
			mv "$weeklydir/*.tar.gz" "$weeklydir/.."
		fi
		eecho "$monthnum" > $weeklydir/month
		eecho "Okay, tracking created, calling doWeekly recursively."
	fi

	if [[ -e $weeklydir/month && $copymonth -gt 0 ]]; then
		if [[ $copymonth -eq $monthnum ]]; then
			eecho "Still on the same month, archiving this week"

			# backup and copy to $weeklydir/week-$weeknum.tar.gz
			tar -chvf "$sourcedir/week-$monthnum.tar" --totals --checkpoint=.1000 "$sourcedir/weekly"

			# gzip it
			#pigz "$sourcedir/week-$monthnum.tar"

			# copy to destination
			#rsync --info=progress2 -avz "$sourcedir/week-$monthnum.tar.gz" "$weeklydir"
			rsync --info=progress2 -avz "$sourcedir/week-$monthnum.tar" "$weeklydir"
			[[ $? == "0" ]] && rm "$sourcedir/week-$monthnum.tar" || exit 1;

		elif [[ $monthnum -gt $copymonth ]]; then
			eecho "New month, archiving previous files (remotely)"

			# Remotely LZMA stuff up
			currdate="$(date +%m-%Y)"
			# sshcommand="ls -A $weeklydir/*.tar | lzma -9 > $monthlydir/$currdate.tar.xz"
			sshcommand="ls -A $weeklydir/*.tar | lzma -9 > $monthlydir/$currdate.tar.xz; rm $monthlydir/*.tar"

			eecho "Performing monthly compression of tars"
			ssh dietpi@rpi "$sshcommand"

			# backup and copy to $weeklydir/week-$weeknum.tar.gz
			eecho "Creating this month's first weekly"
			tar -chvf "$sourcedir/week-$monthnum.tar" --totals --checkpoint=.1000 "$sourcedir/weekly"

			# copy to destination
			rsync --info=progress2 -avz "$sourcedir/week-$monthnum.tar" "$weeklydir"
			[[ $? == "0" ]] && rm "$sourcedir/week-$monthnum.tar" || exit 1;

			# Update tracking file
			eecho "Done! Updating tracking file."
			eecho "$monthnum" > $weeklydir/month
		fi
	fi
	eecho "end of doWeekly"
}

reqChecks() {
	mntpoint="$(mount | grep "$sharename" | cut -d" " -f3)"
	eecho "Detected mount point at $mntpoint for search-term '$sharename'"

	weeklydir="$mntpoint/.backup/$(hostname)-weekly"
	monthlydir="$mntpoint/.backup/$(hostname)-monthly"

	weeknum="$(expr 1 + $(date +%V) - $(date +%V -d $(date +%Y-%m-01)))"
	monthnum="$(date +%m)"

	if ! [[ -d "$sourcedir/weekly" ]]; then eecho "$sourcedir/weekly doesn't exist. Please create it or edit the script to point to the proper folder.";exit 1; fi
	if ! [[ -d "$sourcedir/monthly" ]]; then eecho "$sourcedir/monthly doesn't exist. Please create it or edit the script to point to the proper folder.";exit 1; fi

	if ! [[ -d "$weeklydir" ]]; then eecho "Creating $weeklydir"; mkdir -p $weeklydir; fi
	if ! [[ -d "$monthlydir" ]]; then eecho "Creating $monthlydir"; mkdir -p $monthlydir; fi

	eecho "Testing permissions on '$weeklydir' and '$monthlydir'... This might take a second."
	touch $weeklydir/perms
	# If touch has return-code 1 it means we can't write, for whatever reason-- we'll assume it's permissions
	if [[ $? -eq 1 ]]; then eecho "Hey! The user running the script ($(whoami)) has no permissions to access $weeklydir!"; exit 1; else rm $weeklydir/perms; fi
	touch $monthlydir/perms
	if [[ $? -eq 1 ]]; then eecho "Hey! The user running the script ($(whoami)) has no permissions to access $monthlydir!"; exit 1; else rm $monthlydir/perms; fi
}

if [[ -z $(mount | grep "$sharename") ]]; then
	eecho "Network share not found... Please mount it with FUSE and try again."
	exit
else
	eecho "Starting up"
	reqChecks
fi

# This is commented out because the code that was initially suposed to be separated for "montly backups" \
# ended up being implemented in the weekly backup logic, so I'm just keeping this for reference, along \
# with the doMonthly() function; for reference and not real work
#if [[ $1 == "monthly" || $1 == "m" ]]; then
#	doMonthly
#	if [[ -e "$sourcedir/temp.tar" ]]; then rm "$sourcedir/temp.tar"; fi
#	if [[ -e "$sourcedir/temp.tar.gz" ]]; then rm "$sourcedir/temp.tar.gz"; fi
#el
if [[ $1 == "weekly" || $1 == "w" ]]; then
	doWeekly
	if [[ -e "$sourcedir/temp.tar" ]]; then rm "$sourcedir/temp.tar"; fi
	if [[ -e "$sourcedir/temp.tar.gz" ]]; then rm "$sourcedir/temp.tar.gz"; fi
fi
