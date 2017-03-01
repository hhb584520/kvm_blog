# Serial #

# 1. KVM Serial #

## 1.1 修改 guest ##

	menuentry 'Ubuntu' --class ubuntu --class gnu-linux --class gnu --class os $menuentry_id_option 'gnulinux-simple-cf0213f3-0be3-4074-8e8c-00e0ff164e34' {
	        recordfail
	        load_video
	        gfxmode $linux_gfx_mode
	        insmod gzio
	        insmod part_msdos
	        insmod ext2
	        set root='hd0,msdos1'
	        if [ x$feature_platform_search_hint = xy ]; then
	          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos1 --hint-efi=hd0,msdos1 --hint-baremetal=ahci0,msdos1  cf0213f3-0be3-4074-8e8c-00e0ff164e34
	        else
	          search --no-floppy --fs-uuid --set=root cf0213f3-0be3-4074-8e8c-00e0ff164e34
	        fi
	        linux   /boot/vmlinuz-4.2.0-27-generic root=UUID=cf0213f3-0be3-4074-8e8c-00e0ff164e34 ro console=tty0 console=ttyS0,115200,8n1 3 splash $vt_handoff
	        initrd  /boot/initrd.img-4.2.0-27-generic
	}

添加下面参数

	console=tty0 console=ttyS0,115200,8n1 3

## 1.2 创建虚拟机 ##

	[root@skl-e34 haibin]# cat kvm-rhel7-epc.sh
	#!/bin/sh
	#qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -epc 2M  -monitor pty -cpu host \
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -sgx epc=512K -serial pty -cpu host \
	-device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
	-netdev tap,id=nic0,script=/etc/kvm/qemu-ifup \
	-drive file=/haibin/ubuntu_sgx.qcow2,if=none,id=virtio-disk0 \
	-device virtio-blk-pci,drive=virtio-disk0
	#-device vfio-pci,host=01:00.0 -net none

## 1.3 连接串口 ##

	minicom -D /dev/pts/1


# 2. Xen Serial #