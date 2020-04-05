##!/bin/sh
timestamp=`date "+%Y%m%d_%H%M%S"`
start=`date +%s` #for calculating runtime
dir=$(pwd)

function exit_error () {
	printf "Error @ line:\t%i\n" "${BASH_LINENO[-2]}"
	#removing files
		cd "${dir}"; rm -r "bkps/${timestamp}";
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

#create folders 
	mkdir -p "bkps/${timestamp}"; cd "bkps/${timestamp}"; file="${timestamp}_dev-dump"

#create dumbs
	printf "\n\n\n ***** +++++ ***** creating dump-files ***** +++++ *****\n"
	flashrom -p ch341a_spi -c GD25Q127C/GD25Q128C -V -r "${file}Nr01.bin"
	check_error
	show_runtime
	#2nd dump-file
	gpio write 2 0; sleep 2; gpio write 2 1; sleep 1 #Powering ON SPI_header-VCC
	flashrom -p ch341a_spi -c GD25Q127C/GD25Q128C -V -r "${file}Nr02.bin"
	show_runtime
	
#compare dumps
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
		sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${file}Nr01.bin" > "${file}Nr01.bin.patched"
	#get the sysupgrade file
		sysupgrade_file="openwrt-ramips-mt7621-xiaomi_mir3g-v2-squashfs-sysupgrade.bin"
		wget "https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/${sysupgrade_file}"
		su_hash1=$(curl -s https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/sha256sums | grep ${sysupgrade_file} | cut -f1 -d" ")
		su_hash2=$(sha256sum "${sysupgrade_file}" | cut -f1 -d" ")
		if [ "${su_hash1}" = "${su_hash2}" ]; then
			printf "hashs are identical - continue...\n"
		else
			printf "ERROR: downloading sysupgrade-file --> SHA256sum doesn´t match!\n"
			exit_error  
		fi
	#write openWrt into dumpfile
		dd if="${sysupgrade_file}" of="${file}Nr01.bin.patched" conv=notrunc bs=1 seek=1572864 status=progress
		check_error
		rm "$sysupgrade_file"

#flash file
	printf "\n\n\n ***** +++++ ***** flashing patched file ... ***** +++++ ***** \n"
	flashrom --noverify -p ch341a_spi -c GD25Q127C/GD25Q128C -V -w "${file}Nr01.bin.patched"
	check_error
	printf "\n\n\n ***** +++++ ***** device succesfully patched! ***** +++++ *****\n"

#print runtime
	show_runtime