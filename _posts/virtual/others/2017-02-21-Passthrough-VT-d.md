# 1. 预检查 #

## 1.1 检查硬件 VT-d 是否有开 ##
- 硬件支持和BIOS设置
   
	Intel(R) VT for Directed I/O

- 宿主机内核的配置
	
		CONFIG_INTEL_IOMMU=y
		CONFIG_DMAR=y
		CONFIG_PCI_STUB=y            // 隐藏设备

在启动宿主机系统后，可以通过内核的打印信息来检查 VT-d 是否处于打开可用状态，如下图所示：

    # dmesg | grep DMAR -i
    # dmesg | grep IOMMU -i

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
## 2.1 加载驱动

	modprobe vfio-pci
or

	modprobe pci_stub

## 2.1 隐藏设备 ##
modprobe vfio-pci

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

or 
	-device pci-assign,host=01:00.0,id=mynic -net none

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

# 3. VT-d 概述 #

在QEMU/KVM中，客户机能使用的设备，大致可分为如下三种类型。

- Emulated device：QEMU纯软件模拟的设备。
- Virtio device： 实现VIRTIO API的半虚拟化驱动的设备。
- PCI device assignment： PCI设备直接分配。

模拟I/O设备方式的优点是对硬件平台依赖性较低、可以方便模拟一些流行的和较老久的设备、不需要宿主机和客户机的额外支持，故兼容性高；而其缺点是I/O路径较长、VM-Exit次数很多，故性能较差。一般适用于对I/O性能要求不高的场景，或者模拟一些老旧遗留（legacy）设备（如RTL8139的网卡）。

Virtio半虚拟化设备方式的优点是实现了VIRTIO API，减少了VM-Exit次数，提高了客户机I/O执行效率，比普通模拟I/O的效率高很多；而其缺点是需要客户机中virtio相关驱动的支持（较老的系统默认没有自带这些驱动，Windows系统中需要额外安装virtio驱动），故兼容性较差，而且I/O频繁时的CPU使用率较高。

而第3种方式叫做PCI设备直接分配（Device Assignment，或者PCI pass-through），它允许将宿主机中的物理PCI（或PCI-E）设备直接分配给客户机完全使用，正是本节要介绍的重点内容。较新的x86架构的主要硬件平台（包括服务器级、桌面级）都已经支持设备直接分配，其中Intel定义的I/O虚拟化技术规范为“Intel(R) Virtualization Technology for Directed I/O”（VT-d），而AMD的为“AMD-V”（也叫做IOMMU）。本节以KVM中使用Intel VT-d技术为例来进行介绍（当然AMD IOMMU也是类似的）。

KVM虚拟机支持将宿主机中的PCI、PCI-E设备附加到虚拟化的客户机中，从而让客户机以独占方式访问这个PCI（或PCI-E）设备。通过硬件支持的VT-d技术将设备分配给客户机后，在客户机看来，设备是物理上连接在其PCI（或PCI-E）总线上的，客户机对该设备的I/O交互操作和实际的物理设备操作完全一样，这不需要（或者很少需要）Hypervisor（即KVM）的参与。

运行在支持VT-d平台上的QEMU/KVM，可以分配网卡、磁盘控制器、USB控制器、VGA显卡等给客户机直接使用。而为了设备分配的安全性，它还需要中断重映射（interrupt remapping）的支持，尽管QEMU命令行进行设备分配时并不直接检查中断重映射功能是否开启，但是在通过一些工具使用KVM时（如RHEL6.3中的libvirt）默认需要有中断重映射的功能支持，才能使用VT-d分配设备给客户机使用。

设备直接分配让客户机完全占有PCI设备，在执行I/O操作时大量地减少了（甚至避免）了VM-Exit陷入到Hypervisor中，极大地提高了I/O性能，可以达到和Native系统中几乎一样的性能。尽管Virtio的性能也不错，但VT-d克服了其兼容性不够好和CPU使用率较高的问题。不过，VT-d也有自己的缺点，一台服务器主板上的空间比较有限，允许添加的PCI和PCI-E设备是有限的，如果一个宿主机上有较多数量的客户机，则很难给每个客户机都独立分配VT-d的设备。另外，大量使用VT-d独立分配设备给客户机，让硬件设备数量增加，故增加了硬件投资成本。 为了避免这两个缺点，可以考虑采用如下两个方案。一是，在一个物理宿主机上，仅给少数的对I/O（如网络）性能要求较高的客户机使用VT-d直接分配设备（如网卡），而其余的客户机使用纯模拟（emulated）或使用Virtio以达到多个客户机共享同一个设备的目的。二是，对于网络I/O的解决方法，可以选择SR-IOV让一个网卡产生多个独立的虚拟网卡，将每个虚拟网卡分别分配给一个客户机使用，这也正是后面“SR-IOV技术”这一小节要介绍的内容。另外，它还有一个缺点是，对于使用VT-d直接分配了设备的客户机，其动态迁移功能将会受限，不过也可以在用bonding驱动等方式来缓解这个问题，将在“动态迁移”小节较为详细介绍此方法。

## 3.1 



## 3.2



## 3.3



## 3.4


# 参考资料 #

[2012-forum-VFIO.pdf](/kvm_blog/files/2012-forum-VFIO.pdf)

[VT-d-Posted-Interrupts-final.pdf](/kvm_blog/files/VT-d_Posted_Interrupts_final.pdf)

[vt-directed-io-spec.pdf](/kvm_blog/files/vt-directed-io-spec.pdf)