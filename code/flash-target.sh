##!/bin/sh
timestamp=`date "+%Y%m%d_%H%M%S"`
start=`date +%s`
dev=$1
: "${dev:?Please set a device number!}"

mkdir -p "bkps/${timestamp}_${dev}"; cd "bkps/${timestamp}_${dev}";
file="${timestamp}_dev${dev}-dump"

printf "SPI-Clamp:\tPowerON\n"
gpio mode 2 out; gpio write 2 1; #Powering ON SPI_header-VCC
sleep 1
printf "\n ***** ***** creating dump-files ***** ***** \n\n"
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000  -V -r "${file}Nr01.bin"
if [ $? != 0 ]; then #The return value is stored in $?. 0 indicates success, others indicates error.
	cd ../; rm -r "${timestamp}_${dev}";
	gpio write 2 0; #Powering OFF SPI_header-VCC
	printf "\n !!!!! !!!!! flashrom error !!!!! !!!!! \n\n"
	exit 1
fi
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000  -V -r "${file}Nr02.bin"

#check it the two files are identical, or if something went wrong while reading.
hash1=$(md5sum "${file}Nr01.bin" | cut -f1 -d" ") # only save the hash value
hash2=$(md5sum "${file}Nr02.bin" | cut -f1 -d" ")
printf "\n1st hash: %s\n2nd hash: %s\n" "$hash1" "$hash2"
if [ "${hash1}" = "${hash2}" ]; then
	echo "hashs are identical - continue"
else
	echo "hashs are different - please retry reading the flash."
	exit 1
fi

printf "\nfile to patch: ${file}Nr01.bin\n"
printf "find and replace: 62 6F 6F 74 64 65 6C 61 79 00 00 00 6F 66 66 \n with: 62 6F 6F 74 64 65 6C 61 79 00 00 00 00 00 35"
sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${file}Nr01.bin" > "${file}Nr01.bin.patched"
printf "\n ***** flashing patched file ... *****\n"
flashrom --noverify -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -V -w "${file}Nr01.bin.patched"
printf "\n\n*****  ---> device succesfully patched! <--- *****\n"

printf "\nSPI-Clamp:\tPowerOFF" #Powering OFF SPI_header-VCC
gpio write 2 0;

end=`date +%s`
runtime=$((end-start))
printf "\nruntime: %s seconds\n\n" ${runtime}
