#!/usr/bin/zsh
#
# simple luks open/close function for zsh
# 
# by Jack (jack@ai4me.de)
#
# place this file in a PATH directory
# 
# run with root permissions
#

function usage(){
echo "$0 [-h, --help]"
echo
echo "	-h, --help,	print usage"
echo
echo "	stdin,	[1..n] luks open/close"
echo "			r	reload list"
echo "			a	abort"
echo
echo "This prints a list of numbered luks volumes and opens a chosen device via cryptsetup."
echo "To open or close a volume enter its number. Any other input will lead to no operation."
}

function main(){
# list all devices
if [ -e /dev/mapper ]; then
	a=`ls -dt --color=never /dev/[scm]* /dev/mapper/*|grep -oe "/dev/sd.*" -oe "/dev/mmcblk.*" -oe "/dev/mapper/[^c].*"`
else
	a=`ls -dt --color=never /dev/[scm]*|grep -oe "/dev/sd.*" -oe "/dev/mmcblk.*"`
fi
j=0
ldev=()
if [ -e /dev/mapper ]; then
	ls -d  /dev/mapper/* | grep "/dev/mapper/[^c]*" | while read i; do
		j=$((j+1))
		lm=`cryptsetup status $i | grep device`
		ldev[$j]="$i $lm\n"
	done
fi
j=0
dev=()
endev=()
# walk thru devices, check if mounted, echo
echo $a | while read i;do
	cryptsetup isLuks $i
	if [ "$?" -ne "1" ];then
		j=$((j+1))	
		m=`echo $ldev|grep $i|grep -oe "/dev/mapper/[a-z0-9]*"`
		if [ "$m" != "" ]; then
			echo -en "\e[1;32m"
			endev[$j]=$m
		fi
		echo -e "\t$j  $i\t\t$m\e[0m"
		m=""
		dev[$j]=$i
	fi
done
echo "(1)"
read b
# no input use 1
if [ "$b" = "" ];then
	b=1
fi
# command from user
if [ "$b" = "r" ]; then
	main
	b="a"
fi
# invalid device number
if ! [[ $(echo {1..$j}) =~ $b ]];then
	return
fi
# use pmount to mount or unmount
if [ "$endev[$b]" = "" ];then
	num=`ls /dev/mapper/* | grep "lusb" | wc -l`
	echo "cryptsetup luksOpen $dev[$b] lusb$num";cryptsetup luksOpen $dev[$b] lusb$num
else
	echo "cryptsetup luksClose $endev[$b]";cryptsetup luksClose $endev[$b]
fi	
}



if [ ! "$1" = "" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
	usage
	return
fi

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	return
fi

main
