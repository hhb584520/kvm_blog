#!/bin/bash
mac="00:16:3e:14:e4:d4"
((mac6=0x`echo $mac | awk -F: '{print $6}'`));
for i in `seq 1 $1`
do
        cp xen-rhel7u2.conf  xen-rhel7u2-$i.conf
        qemu-img-xen create -b /share/xvs/img/linux/ia32e_rhel7u2.img -f qcow2 rhel7u2-$i.qcow2
        sed -i "s/vm1/vm1-$i/g" xen-rhel7u2-$i.conf

        macnew=$(echo $(awk 'BEGIN{printf("%x", '$mac6'+'$i')'}))

        sed -i "s/d4/$macnew/g"  xen-rhel7u2-$i.conf
        sed -i "s/.qcow2,/-$i.qcow2,/g"  xen-rhel7u2-$i.conf
	
	xl create  xen-rhel7u2-$i.conf
done
