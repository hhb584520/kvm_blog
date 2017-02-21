# 1. 预检查 #

## 1.1 检查硬件 VT-d 是否有开 ##
   省略

## 1.2 添加 intel_iommu=on ##

	menuentry 'Red Hat Enterprise Linux Server (4.6.0+) 7.2 (Maipo)' --class red --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-86ddb3e6-07fc-47a9-9e69-d1591ca0942b' {
	        load_video
	        set gfxpayload=keep
	        insmod gzio
	        insmod part_msdos
	        insmod xfs
	        set root='hd0,msdos1'
	        if [ x$feature_platform_search_hint = xy ]; then
	          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos1 --hint-efi=hd0,msdos1 --hint-baremetal=ahci0,msdos1 --hint='hd0,msdos1'  ef9ce169-d238-44a7-bebb-99bc2805a0c0
	        else
	          search --no-floppy --fs-uuid --set=root ef9ce169-d238-44a7-bebb-99bc2805a0c0
	        fi
	        linux16 /vmlinuz-4.6.0+ root=/dev/mapper/rhel-root ro crashkernel=auto rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet LANG=en_US.UTF-8 intel_iommu=on
	        initrd16 /initramfs-4.6.0+.img
	}


# 2. 操作设备 #
## 2.1 隐藏设备 ##

For Xen:

	# ethtool -i eth0 
      0000:01:00.0 ($bdf)
	# xl pci-assignable-add $bdf

or
	# ethtool -i eth0 
    # lspci -Dn -s "$bdf" | awk '{print $3}' | sed "s/:/ /"
      8086 105e  ($pciid)
    # echo -n "$pciid" > /sys/bus/pci/drivers/pci-stub/new_id
    # echo -n "$bdf" > /sys/bus/pci/devices/"$bdf"/driver/unbind
    # echo -n "$bdf" > /sys/bus/pci/drivers/pci-stub/bind


For KVM:

	# ethtool -i eth0
	  0000:01:00.0 ($bdf)
    # lspci -Dn -s "$bdf" | awk '{print $3}' | sed "s/:/ /"
      8086 105e  ($pciid)
    # echo -n "$pciid" > /sys/bus/pci/drivers/vfio-pci/new_id
    # echo -n "$bdf" > /sys/bus/pci/devices/"$bdf"/driver/unbind
	# echo -n "$bdf" > /sys/bus/pci/drivers/vfio-pci/bind

## 2.2 显示设备 ##

For Xen:

    # xl pci-assignable-remove $bdf
	# echo -n "$bdf" > /sys/bus/pci/drivers/e1000e/bind


For KVM:

    # echo -n "$bdf" > /sys/bus/pci/drivers/vfio-pci/unbind
    # echo -n "$bdf" > /sys/bus/pci/drivers/e1000e/bind


## 2.3 配置文件 ##

vim **kvm-rhel7-epc-passthrough.sh**

	# !/bin/sh
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host \
	-device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
	-netdev tap,id=nic0,script=/etc/kvm/qemu-ifup \
	-drive file=/root/ubuntu_sgx.qcow2,if=none,id=virtio-disk0 \
	-device virtio-blk-pci,drive=virtio-disk0 \
	-device vfio-pci,host=01:00.0 -net none


vim **xen-rhel7-epc-passthrough.conf**

	builder= "hvm"
	name= "vm1"
	memory = 4096
	vcpus=16
	vif = [ 'type=ioemu, mac=00:16:3e:14:e4:d4, bridge=xenbr0' ]
	disk = [ '/root/rhel7u2_xen_sgx.qcow2,qcow2,sda,rw' ]
	vnc=1
	stdvga=1
	acpi=1
	hpet=1
	pci= [ ‘01:00.0’ ]


# 参考资料 #
2012-forum-VFIO.pdf
VT-d Posted Interrupts-final.pdf
[vt-directed-io-spec.pdf	](/kvm_blog/files/vt-directed-io-spec.pdf)