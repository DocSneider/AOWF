##!/bin/sh
timestamp=`date "+%Y%m%d_%H%M%S"`
start=`date +%s` #for calculating runtime
dir=$(pwd)


function exit_error () {
	printf "Error @ line:\t%i\n" "${BASH_LINENO[-2]}"
	show_runtime
	exit 1
}

function check_error () {
	if [ $? != 0 ]; then #The return value is stored in $?. 0 indicates success, others indicates error.
		exit_error
	fi
}

function show_runtime () {
	end=`date +%s`
	runtime=$((end-start))
	printf "\nruntime: %s seconds\n\n" ${runtime}
}

#get backup-file	
	printf "backup-file to patch:"
	read -r -e backup_file
	printf "File(path)=%s\n" "$backup_file"

#get sysupgrade file	
	printf "Sysupgrade image to flash: "
	read -r -e sysupgrade_file
	printf "File(path)=%s\n" "$sysupgrade_file"

#patch file
	#enable bootdelay
		printf "\n***** +++++ ***** enable bootmenue ***** +++++ *****\n"
		sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${backup_file}" > "${backup_file}.patched"
	#write openWrt into dumpfile
		printf "\n***** +++++ ***** writing openWrt into flash-dump ***** +++++ *****\n"
		dd if="${sysupgrade_file}" of="${backup_file}.patched" conv=notrunc bs=1 seek=1572864 status=progress
		check_error

#flash file
	printf "\n\n\n ***** +++++ ***** flashing patched file ... ***** +++++ ***** \n"
	flashrom -p ch341a_spi -V -w "${backup_file}.patched"
	check_error
	printf "\n\n\n ***** +++++ ***** device succesfully patched! ***** +++++ *****\n"

#print runtime
	show_runtime
