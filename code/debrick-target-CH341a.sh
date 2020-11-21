##!/bin/sh
timestamp=`date "+%Y%m%d_%H%M%S"`
start=`date +%s` #for calculating runtime
dir=$(pwd)


function exit_error () {
	printf "Error @ line:\t%i\n" "${BASH_LINENO[-2]}"
	#removing files
		cd "${dir}"; rm -r "dumps/${timestamp}"
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

#get sysupgrade file	
	printf "Sysupgrade image to flash: "
	read -r -e sysupgrade_file
	printf "File(path)=%s\n" "$sysupgrade_file"

#create folders
	printf "Creating folders for dumps.\n"
	mkdir -p "dumps/${timestamp}"; cd "dumps/${timestamp}"; file="${timestamp}_dump"

#create 2 dumbs
	printf "\n***** +++++ ***** creating dump-files ***** +++++ *****\n"
	flashrom -p ch341a_spi -V -r "${file}Nr01.bin"
	check_error; show_runtime
	#2nd dump-file
	flashrom -p ch341a_spi -V -r "${file}Nr02.bin"
	check_error; show_runtime
	
#compare dumps
	printf "\n***** +++++ ***** comparing dump-files ***** +++++ *****\n"
	dump_hash1=$(md5sum "${file}Nr01.bin" | cut -f1 -d" ") # only get the hash value
	dump_hash2=$(md5sum "${file}Nr02.bin" | cut -f1 -d" ")
	if [ "${dump_hash1}" = "${dump_hash2}" ]; then
		printf "hashs are identical - continue...\n"
	else
		printf "ERROR: dumping flash content --> md5sum´s doesn´t match - please check connection & retry.\n"
		exit_error
	fi

#patch file
	#enable bootdelay
		printf "\n***** +++++ ***** enable bootmenue ***** +++++ *****\n"
		sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${file}Nr01.bin" > "${file}Nr01.bin.patched"
	#write openWrt into dumpfile
		printf "\n***** +++++ ***** writing openWrt into flash-dump ***** +++++ *****\n"
		dd if="${sysupgrade_file}" of="${file}Nr01.bin.patched" conv=notrunc bs=1 seek=1572864 status=progress
		check_error

#flash file
	printf "\n\n\n ***** +++++ ***** flashing patched file ... ***** +++++ ***** \n"
	flashrom -p ch341a_spi -V -w "${file}Nr01.bin.patched"
	check_error
	printf "\n\n\n ***** +++++ ***** device succesfully patched! ***** +++++ *****\n"

#print runtime
	show_runtime
