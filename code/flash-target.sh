#!/bin/sh
start=`date +%s`;
dev=$1
: "${dev:?Please set a device number!}"

cd ../bkps; mkdir ${dev}; cd ${dev};
file="dev${dev}-dump"

printf "\n ***** ***** creating dump-files ***** ***** \n\n"
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -c GD25Q128C -V -r "${file}Nr01.bin"
	if [ $? != 0 ]; then #The return value is stored in $?. 0 indicates success, others indicates error.
		cd ../; rm -r ${dev};
		printf "\n\n\n !!!!! !!!!! flashrom error !!!!! !!!!! \n\n"
		exit 1
	fi
flashrom -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -c GD25Q128C -V -r "${file}Nr02.bin"
printf "\n\n ***** ***** created 2 DUMPS ***** ***** \n"

printf "\nfile to patch: ${file}Nr01.bin\n"
echo "find and replace: 62 6F 6F 74 64 65 6C 61 79 00 00 00 6F 66 66 \n with: 62 6F 6F 74 64 65 6C 61 79 00 00 00 00 00 35"
sed 's/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x6F\x66\x66/\x62\x6F\x6F\x74\x64\x65\x6C\x61\x79\x00\x00\x00\x00\x00\x35/g' "${file}Nr01.bin" > "${file}Nr01.bin.patched"
echo "\n ***** flashing patched file ... *****\n"
flashrom --noverify -p linux_spi:dev=/dev/spidev0.0,spispeed=1000 -c GD25Q128C -V -w "${file}Nr01.bin.patched"
printf "\n\n*****  ---> device succesfully patched! <--- *****\n"

end=`date +%s`
runtime=$((end-start))
printf "\n\nruntime: %s seconds\n" $runtime
