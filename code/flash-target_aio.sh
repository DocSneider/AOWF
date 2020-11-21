##!/bin/sh
timestamp=`date "+%Y%m%d_%H%M%S"`
start=`date +%s` #for calculating runtime
dir=$(pwd)

function exit_error () {
	printf "Error @ line:\t%i\n" "${BASH_LINENO[-2]}"
	#removing files
		cd "${dir}"; rm -r "bkps/${timestamp}";
	#Powering DOWN SPI_header-VCC
		gpio write 2 0; sleep 0.5
		printf "\nSPI-Clamp: PowerOFF\n"
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
	printf "SPI-Clamp:\tPowerON\n"; gpio mode 2 out; gpio write 2 0; sleep 2; gpio write 2 1; sleep 1 #Powering ON SPI_header-VCC
	flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -V -r "${file}Nr01.bin"
	check_error
	#2nd dump-file
	gpio write 2 0; sleep 2; gpio write 2 1; sleep 1 #Powering ON SPI_header-VCC
	flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -V -r "${file}Nr02.bin"

#compare dumps
	hash1=$(md5sum "${file}Nr01.bin" | cut -f1 -d" ") # only get the hash value
	hash2=$(md5sum "${file}Nr02.bin" | cut -f1 -d" ")
	printf "\n1st hash: %s\n2nd hash: %s\n" "$hash1" "$hash2"
	if [ "${hash1}" = "${hash2}" ]; then
		printf "hashs are identical - continue\n"
	else
		printf "hashs are different - please retry reading the flash.\n"
		exit_error
	fi

#patch file
	#enable bootdelay
		sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${file}Nr01.bin" > "${file}Nr01.bin.patched"
	#write openWrt into dumpfile
		wget "https://downloads.openwrt.org/snapshots/targets/ramips/mt7621/openwrt-ramips-mt7621-xiaomi_mir3g-v2-squashfs-sysupgrade.bin"
		sysupgrade_file="openwrt-ramips-mt7621-xiaomi_mir3g-v2-squashfs-sysupgrade.bin"
		dd if="${sysupgrade_file}" of="${file}Nr01.bin.patched" conv=notrunc bs=1 seek=1572864 status=progress
		check_error
		printf "\n\n\n ***** +++++ ***** dd done ***** +++++ ***** \n"
		rm "$sysupgrade_file"

#flash file
	printf "\n\n\n ***** +++++ ***** flashing patched file ... ***** +++++ ***** \n"
	flashrom --noverify -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -V -w "${file}Nr01.bin.patched"
	check_error
	printf "\n\n\n ***** +++++ ***** device succesfully patched! ***** +++++ *****\n"
	gpio write 2 0; printf "\nSPI-Clamp: PowerOFF\n"

#print runtime
	show_runtime
