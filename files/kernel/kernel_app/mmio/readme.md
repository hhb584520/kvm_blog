# 1. Usage:
  
## find a eth
	lspci | grep Eth

## get region addr
	lspci -vv -s $bdf
	lspci -vv -s $bdf | grep "Region .: Memory" | awk -F " " '{print $5}'

## unbind device
	echo -n "$bdf" > /sys/bus/pci/devices/"$bdf"/driver/unbind

## module
	make
    insmod bmmio.ko addr=0x**** rw_flag=1/2/3   // 1=read only, 2 write only, 3 read and write
	dmesg -c
	rmmod bmmio.ko

# 2.Ref:
  http://www.it165.net/os/html/201208/3124.html
