# 1. 网卡配置 #

## 1.1 虚拟网桥配置 ##
### 1.1.1 KVM ###

**新的方法**  
qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 64 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -device virtio-net-pci,netdev=nic0, -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup –daemonize

qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 64 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -device e1000,netdev=nic0, -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup –daemonize

**老的方法**  
qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 2 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -net nic,model=rtl8139 -net tap,name=tap0,script=/etc/kvm/qemu-ifup  -daemonize


**备注：**

	[root@hhb-kvm ]# cat /etc/kvm/qemu-ifup
	#!/bin/sh
	
	switch=$(brctl show| sed -n 2p |awk '{print $1}')
	/sbin/ifconfig $1 0.0.0.0 up
	/usr/sbin/brctl addif ${switch} $1

### 1.1.2 XEN

配置文件添加如下项
	
	vif = [ 'type=ioemu, mac=00:16:3e:14:e4:d5, bridge=xenbr0' ]

## 1.2 虚拟直通网卡配置 ##
**直通网卡**

qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 64 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -device vfio-pci,host=${bdf} -net none –daemonize

## 1.3 参数说明 ##
    
qemu-system_x86-64启动加如下参数
-net nic,model=rtl8139 -net tap,script=/etc/kvm/qemu-ifup
-device virtio-net-pci,netdev=nic0,mac=52:54:00:0c:12:78 -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup

"-device ?" 参数查看到有哪些可用的驱动器，可以用 "-device driver,?"查看到某个驱动器支持的所有属性。
-device pci-assign,host=08:00.0,id=mydev0,addr=0x6

(1) -net nic

为客户机创建一个网卡，这个主要是模拟网卡

(2) -net user

让客户机使用不需要管理员权限的用户模式网络，如“-net nic -net user"

(3) -net tap

使用宿主机的 TAP 网络接口来帮助客户机建立网络。使用网桥连接和 NAT 模式网络的客户机都会使用到 -net tap参数。如 "-net nic -net tap,ifname=tap1,script=/etc/qemu-ifup,downsript=no"
        
(4) -net dump
转存出网络中的数据流量，之后可以用 tcpdump或wireshark 分析。

(5) -net none
当不需要配置任何网络设备时，需要使用。默认是会被设置"-net nic -net user"