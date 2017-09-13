# 配置文件 #

- 配置文件帮助
- CPU
- MEM
- 存储
- 网络
- 串口
- 显示
- 其它

## 1. xl 和 qemu-system-x86_64 的帮助
### 1.1 XL ###

	1. 下载Xen的源码
	2. 执行编译命令
	   make docs && make install-docs
	3. 查看xl 配置文件的参数 man xl.cfg

	https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html

基本上 xen 配置文件都可以在这里查到

	https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html

通过源码安装

	git clone https://xenbits.xen.org/git-http/xen.git
	make docs
	make install_docs
	man xl.cfg

### 1.2 Qemu-system-x86_64 ###
    
	qemu-system-x86_64 --help
    qemu-system-x86_64 -cpu help 

	https://wiki.archlinux.org/index.php/QEMU_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
	http://download.qemu-project.org/qemu-doc.html

### 1.3 启动虚拟机的例子 #

**KVM** 

	qemu-system-x86_64 -enable-kvm -m 2048 -smp 4 -cpu kvm64 \
	 -device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
	 -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup \
	 -drive file=/share/xvs/var/rhel7.qcow,if=none,id=virtio-disk0 \
	 -device virtio-blk-pci,drive=virtio-disk0 \
	 -monitor pty

	[root@hhb-kvm kvm]# cat qemu-ifup
	#!/bin/sh
	
	switch=$(brctl show| sed -n 2p |awk '{print $1}')
	/sbin/ifconfig $1 0.0.0.0 up
	/usr/sbin/brctl addif ${switch} $1

**Xen**

	builder= "hvm"
	name= "vm1-1"
	memory=4096
	vcpus=64
	disk = [ '/share/xvs/haibin/288cpus/rhel7u2-1.qcow2,qcow2,sda,rw', '/share/xvs/haibin/288cpus/linux.qcow2,qcow2,sdb,rw' ]
	vif = [ 'type=ioemu, mac=00:16:3e:14:e4:d5, bridge=xenbr0' ]
	vnc=1
	stdvga=1
	acpi=1
	hpet=1
	usb=1
	usbdevice='tablet'

## 2.CPU
### 2.1 CPU 参数
CPU(s) (逻辑CPU数) = Socket(s) * Core(s) per socket  * Thread(s) per core

	# lscpu
	CPU(s):                56			逻辑CPU数
	On-line CPU(s) list:   0-55			
	Thread(s) per core:    2			每个核上的逻辑CPU个数
	Core(s) per socket:    14			每个物理CPU上核的个数
	Socket(s):             2			物理CPU数

#### 2.1.1 KVM
如果不设置，默认值除 maxcpus 外，其余全为 1
    
-smp n[,maxcpus=cpus][,cores=cores][,threads=threads][,sockets=sockets]

    可以使用下面命令查看：
    info cpus 
    ps -efL | grep qemu   # 其中 -L可以查看线程 ID。

### 2.2 CPU 模型
#### 2.2.1 KVM
- 查看当前的 QEMU 支持的所有 CPU 模型（cpu_model, 默认的模型为qemu64）
        
	qemu-system-x86_64 -cpu ?
	其中加了 [] ，如 qemu64, kvm64 等CPU模型是 QEMU命令中原生自带 (built-in) 的，现在所有的定义都放在 target-i386/cpu.c 文件中

- 尽可能多地将物理CPU信息暴露给客户机 ： `-cpu host`

- 改变 qemu64 类型CPU的默认类型 ： `-cpu qemu64,model=13`

- 可以某个CPU模型作为基础，然后用“+”号将部分的CPU特性添加到基础模型中去：`-cpu qemu64,+avx`

#### 2.3 进程的处理器亲和性和 vCPU 的绑定 #
注：特别是在多处理器、多核、多线程技术使用的情况下，在NUMA结构的系统中，如果不能基于对系统的CPU、内存等有深入的了解，对进程的处理器亲和性进行设置导致系统的整体性能的下降而非提升。

**隔离 CPU**

     vi grub.cfg
     title Red Hat ........
         root (hd0,0)
         kernel /boot/vmlinuz-3.8 ro root=UUID=****** isoplus=2,3

    检查是否隔离成功，第一行的输出明显大于2、3行。
            ps -eLO psr | grep 0 | wc -l 
            ps -eLO psr | grep 2 | wc -l
            ps -eLO psr | grep 3 | wc -l

#### 2.3.1 KVM  

**启动一个客户机**
    
	qemu-system-x86_64 rhel6u3.img -smp 2 -m 512 -daemonize

**绑定 vCPU**

- 查看代表 vCPU 的QEMU进程

    ps -eLo ruser,pid,ppid,lwp,psr,args | grep qemu | grep -v grep

- 绑定代表整个客户机的 QEMU 进程，使其运行在 cpu2/cpu3 上，其中 3963为 qemu主线程、3967和3968分别为两个 vCPU.

    taskset -p 0x4 3963
    taskset -p 0x4 3967
    taskset -p 0x8 3968

- 查看绑定是否有效
       
	ps -eLo ruser,pid,ppid,lwp,psr,args | grep qemu | awk '{if$5==2 print $0}'
    Ctrl + Alt +2 -->  info cpus

#### 2.3.2 Xen  
**启动一个客户机**

**绑定 vCPU**
XEN how to use vcpu pin cpu

	#!/bin/bash
	domid=$1
	cpus_num=$2
	for i in `seq 0 $cpus_num`
	do
	xl vcpu-pin $domid $i $i
	done

you can put this in the vm config
	
cpus="CPU-LIST"

	List of which cpus the guest is allowed to use. Default is no pinning at all (more on this below). A "CPU-LIST" may be specified as follows:
	"all"
	    To allow all the vcpus of the guest to run on all the cpus on the host.
	
	"0-3,5,^1"
	    To allow all the vcpus of the guest to run on cpus 0,2,3,5. Combining this with "all" is possible, meaning "all,^7" results in all the vcpus of the guest running on all the cpus on the host except cpu 7.

### 2.4 CPU Hotplug Support in QEMU
-----
[1] http://www.linux-kvm.org/images/0/0c/03x07A-Bharata_Rao_and_David_Gibson-CPU_Hotplug_Support_in_QEMU.pdf
[2] https://www.youtube.com/watch?v=WuTPq8XgEbY
 
## 3. 内存
### 3.1 内存设置基本参数
(1) -m megs 参数

[root@skl-sp2 ~]# qemu-system-x86_64 -m ?
qemu-system-x86_64: -m ?: Parameter 'size' expects a size
You may use k, M, G or T suffixes for kilobytes, megabytes, gigabytes and terabytes.
默认单位 MB，也可以使用 G 来表示GB单位的内存大小，如“-m 4G”表示 4GB 内存大小。

这里看到的内存都不准，主要是该命令显示的大小是总内存除去了内核执行文件占用内存和一些系统保留的内存之后能使用的内存
cat /proc/meminfo
free -m真实的内存大小
dmesg | grep Memory

(2) -mem-path path  参数
     启动时即分配全部的内存，而不是根据客户机请求而动态分配内存，主要是分配大页内存如 “-mem-path /dev/hugepages”。

(3) -mem-prealloc  参数
      启动时即分配全部的内存，而不是根据客户机请求而动态分配，必须与 "-mem-path"参数一起使用。

(4) -balloon 开启内存气球的设置
     “-balloon virtio”为客户机提供 virtio_balloon 设备，从而通过内存气球 balloon, 可以在QEMU monitor 中用
"balloon" 命令来调节客户机占用内存的大小（-m 参数设置的内存范围内）。

### 3.2 Numa
#### 3.2.1 KVM Numa
qemu-system-x86_64 \
-enable-kvm \
-drive format=raw,file=/root/vdisk.img,index=0,media=disk \
-cpu host \
-m 20480 \
-smp cpus=64,cors=64,threads=1,sockets=1 \
-object memory-backend-ram,size=10240M,host-nodes=0,policy=bind,id=node0 \
-numa node,nodeid=0,cpus=0-63,memdev=node0 \
-object memory-backend-ram,size=10240M,host-nodes=1,policy=bind,id=node1 \
-numa node,nodeid=1,memdev=node1 \
-acpitable file=/sys/firmware/acpi/tables/PMTT 

#### 3.2.2 Xen Numa
** Xen Hypervisor**

Compile and install latest Xen. RH 7.2 is preferable dom0 OS.
Add `dom0_mem=2048M,max:4096M` to Xen boot command line to limit dom0 memory occupation.
Reboot and boot Xen.
`xl info –n` to check whether hypervisor can see 2 nodes in Quadrant Mode (8 nodes in SNC-4 Mode).
 
** Build guest with vNUMA**
 
In guest configuration file, add something like:

```
memory=2048
vnuma = [ ["pnode=0", "vcpus=0-3", "size=1024", "vdistance=10, 31"],
		  ["pnode=1", "size=1024", "vdistance=31, 10" ]
```
Normally you can use the values from "xl info -n" or "numactl -H" to fill size and vdistance list.


## 4.存储
### 4.1 存储配置和启动顺序
**Xen:**

https://wiki.xen.org/wiki/Using_Xen_PV_Drivers_on_HVM_Guest

**KVM**

    -boot  [ order=drives ] [,once=drives] [,menu=on|off][,splash=splashfile][,splash-time=sp-time]
       -> order : 'a', 'b' 分别表示第一和第二个软驱，用 ‘c’ 表示表示第一个硬盘，用 'd' 表示 CD-ROM 光驱，用 ’n' 表示从网络启动。
       -> once : 表示设置第一次启动的顺序。
       -> menu : 表示交互式的启动菜单。

     -boot order=dc -hda rhel6u3.img -cdrom rhel6u3.iso 
    让 rhel6u3.img 文件作为 IDE 磁盘，安装光盘 rhel6u3.iso 作为IDE光驱，并且从光盘启动客户机，从而让客户机进入到系统安装的流程中。


### 4.2 存储的基本配置项
**KVM**

    -hda file
        将 file 镜像文件作为客户机中的第一个 IDE 设备，在客户机中表现为 /dev/hda 设备（若客户机中使用 PIIX_IDE驱动）或 /dev/sda 设备（若客户机中使用 ata_piix 驱动） 。
    -fda file
        将 file 作为第一个软盘设备，在客户机中为 /dev/fd0
    -cdrom file
        将 file 作为客户机中的光盘 CD-ROM，在客户机中通常表现为 /dev/cdrom
    -mtdblock file
        使用 file 文件作为客户机自带的一个 Flash 存储器。
    -sd file
        使用 file 文件作为客户机中的 SD卡

    较新的版本 Qemu 还提供了 -driver 参数来详细定义一个存储驱动器，该参数的具体形式如下：
    -drive option[,option[,option[,option[,...]]]
    -> file=file 使用 file 文件作为镜像文件加载到客户机的驱动器中。
    -> if=interface 指定驱动器使用的接口类型，可用的类型有：ide, scsi, sd, mtd, floopy, pflash, virtio, 等等。
    -> cache=cache 设置宿主机对块设备数据访问中的 cache 情况，可以设置为 none, off, writeback, writethrough。
    -drive file=rhel6u3.img,if=virtio 的参数配置使用 virtio-block 驱动来支持该磁盘文件。

	qemu-system-x86_64 -m 1024 -smp 2 rhel6u3.img
	qemu-system-x86_64 -m 1024 -smp 2 -hda rhel6u3.img
	qemu-system-x86_64 -m 1024 -smp 2 -drive file=rhel6u3.img,if=ide,cache=writethrough

**Xen**

	disk = [ '/share/rhel7.qcow2,qcow2,hda,rw', '/share/linux.qcow2,qcow2,hdb,rw' ]

### 4.3 创建虚拟机的镜像
**KVM**

qemu-img 支持非常多种的文件格式，可以通过 “qemu-img -h” 查看其命令帮助得到

Supported formats: qcow2 blkdebug luks file qed vpc bochs vvfat sheepdog nbd dmg cloop vmdk blkreplay host_cdrom host_device qcow tftp ftp vdi raw ftps vhdx https http null-aio null-co blkverify parallels

- raw 原始的磁盘镜像格式，也是 qemu-img 命令默认的文件格式。这种文件格式的优势在于它非常简单且非常容易移植到其它模拟器（Qemu也是一种模拟器）上面去使用。如果客户机文件系统（如 Linux的 ext2/ext3/ext4、windows 的NFS）支持“空洞”，那么镜像文件只有在被写有数据的扇区才会真正占用磁盘空间。不过采用 dd 命令创建的镜像也是 raw 格式，不过那是一开始就让镜像实际占用了分配的空间，而没有使用稀疏文件的方式对待空洞来节省磁盘空间。

- qcow2是 QEMU 目前推荐的镜像格式，它是功能最多的格式。它支持稀疏文件以节省存储空间，它支持可选的AES加密以提高镜像文件的安全性，支持基于 zlib 的压缩，支持一个镜像文件中有多个虚拟机快照。
     在 qemu-img 命令中 qcow2 支持如下几个选项：
    -> backing_file，用于指定后端镜像文件。
    -> backing_fmt，设置后端镜像的镜像格式。
    -> cluster_size，设置镜像中簇的大小，取值在 512B 到 2MB之间，默认值为64KB。较小的簇可以节省镜像文件的空间，而较大的簇可以带来更好的性能。
    -> preallocation，设置镜像文件的预分配模式，其值可为 off, metadata ，full 之一.
    -> encryption，用于设置加密，当它等于 "on" 时，镜像被加密。它使用 128 位密钥的 AES 加密算法，故其密码长度可达 16个字符，可以保证加密的安全性较高。
        qemu-img convert -o encryption
qemu-img 命令, qemu-img 是 QEMU 的磁盘管理工具，在完成了QEMU后，就会默认编译好工具
   
- 对磁盘镜像文件做一致性检查: `qemu-img check rhel6u3.qcow2`

- 创建磁盘镜像: `qemu-img create -f raw image_file 4G`
提示: 在QEMU Wikibook QEMU images参见更多信息
硬盘镜像是一个文件，存储虚拟机硬盘上的内容。除非直接从 CD-ROM 或网络引导并且不安装系统到本地，运行 QEMU 时都需要硬盘镜像。
一个硬盘镜像可能是 raw镜像, 和客户机器上看到的内容一模一样，主机上占用的空间客户机上的大小一样。这个方式 I/O 效率最高，但是因为客户机器上没使用的空间也被占用，所以有点浪费空间。另外一种方式是qcow2 格式，仅当客户系统实际写入内容的时候，才会分配镜像空间。对客户机器来说，硬盘大小是完整大小，但是在主机系统上实际仅占用和很小的空间。使用这种方式会影响效率。用 dd 或 fallocate 也可以创建一个 raw 镜像。
Warning: 如果硬盘镜像存储在 Btrfs 系统上，在创建前请考虑禁用写时复制。

### 4.4 Overlay storage images ##
指的是基于 base 镜像参加的镜像:

	$ qemu-img create -o backing_file=img1.raw,backing_fmt=raw -f qcow2 img1.qcow2
	-o backing_file=img1.raw,backing_fmt 等价于 -b img1.raw
	qemu-img create -f qcow2 -o ? temp.qcow

这种方式创建的修改，我们可以直接提交修改到已经创建的镜像中，要么在 QEMU monitor 中使用 “commit” 命令或使用“qemu-img commit"命令去手动提交这些改动
如果想将快照里的相关操作合并到原始镜像中，可以通过下面命令

命令：# qemu-img commit -f qcow2 img1.qcow2

这里还可以基于 qcow 建立 qcow, 也可以采用 commit 方式提交

$ qemu-img rebase -b /new/img1.raw /new/img1.qcow2

下面命令会检查 backing_file，是安全的但是比较慢
$ qemu-img rebase -u -b /new/img1.raw /new/img1.qcow2

### 4.5 调整镜像大小
警告: 调整包含NTFS引导文件系统的镜像将无法启动已安装的操作系统. 完整的解释和解决办法参见 [1].
执行 qemu-img 带 resize 选项调整硬盘驱动镜像的大小.它适用于 raw 和 qcow2. 例如, 增加镜像 10 GB 大小, 运行:

	$ qemu-img resize disk_image +10G
	$ qemu-img resize rhel7u2-1.qcow2 -19G 

After enlarging the disk image, you must use file system and partitioning tools inside the virtual machine to actually begin using the new space. When shrinking a disk image, you must first reduce the allocated file systems and partition sizes using the file system and partitioning tools inside the virtual machine and then shrink the disk image accordingly, otherwise shrinking the disk image will result in data loss!    

**扩展 QCOW 的方法**

- 创建 qcow2 文件：`qemu-img create -b /rhel7u2.img -f qcow2 /rhel7u2.qcow2 50G`
- 创建 guest 用刚刚的 qcow2 文件 
- 扩容分区
    
	fdisk /dev/vda
	pvcreate /dev/sda3
	vgextend  rhel /dev/vda3
	lvextend -L +30G /dev/rhel/root
	xfs_growfs /dev/rhel/root

**查看镜像文件的信息**

    qemu-img info rhel6u3.img

### 4.6 boot guest from USB
 
The command below can boot guest from USB and install OS to harddisk.
 
qemu-system-x86_64 -M q35 --enable-kvm -m 512 -redir tcp:8022::22 -monitor stdio -device nec-usb-xhci -device usb-host,vendorid=0x0951,productid=0x1666,bootindex=1  -hda /home/test.qcow2 

## 5. Network
### 5.1 虚拟机网桥配置 ###
#### 5.1.1 KVM ####
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

#### 5.1.2 XEN

配置文件添加如下项
	
	vif = [ 'type=ioemu, mac=00:16:3e:14:e4:d5, bridge=xenbr0' ]

### 5.2 虚拟直通网卡配置
**直通网卡**

qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 64 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -device vfio-pci,host=${bdf} -net none –daemonize

### 5.3 参数说明
    
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

## 6. Serial ##
**添加串口参数**

	menuentry 'Ubuntu' {
        load_video
		......
        linux   /boot/vmlinuz-4.2.0-27-generic root=UUID=cf0213...34 ro console=tty0 console=ttyS0,115200,8n1 3
	}

添加下面参数: **console=tty0 console=ttyS0,115200,8n1 3**
修改 guest /boot/grub2/grub.conf

- sudo mount ia32e_rhel7u2_kvm.img -o offset=1048576 /mnt
- fdisk -l ia32e_rhel7u2_kvm.img
	
	Disk rhel7u2_kvm.img: 21.5 GB, 21474836480 bytes, 41943040 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x000e5f14

    Device Boot      Start         End      Blocks   Id  System
	rhel7u2_kvm.img1   *        2048     1026047      512000   83  Linux
	rhel7u2_kvm.img2         1026048    41943039    20458496   8e  Linux LVM

- mount ia32e_rhel7u2_kvm.img -o offset=1048576 /mnt
- vim /mnt/grub2/grub.conf
    
	change "rhgb quiet" to "console=ttyS0,115200,8n1"

- umount /mnt


### 6.1 KVM Serial
#### 6.1.1 创建虚拟机

	#!/bin/sh
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -serial pty -cpu host \
	-device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
	-netdev tap,id=nic0,script=/etc/kvm/qemu-ifup \
	-drive file=/haibin/ubuntu_sgx.qcow2,if=none,id=virtio-disk0 \
	-device virtio-blk-pci,drive=virtio-disk0

#### 6.1.2 连接串口

	minicom -D /dev/pts/1

### 6.2 Xen Serial
#### 6.2.1 创建虚拟机

	[root@l1xen haibin]# cat config.test
	builder = "hvm"
	......
	serial = 'pty'
	......
	on_crash = 'preserve'

#### 6.2.2 连接串口

	xl console domid

## 7. display
### 7.1 VNC的使用 ##
**普通VNC使用**
   
- 启动虚拟机的参数 -vnc :2
- 客户机：vncviewer :2

**反转 VNC**

- 宿主机：vncviewer -listen :2
- 客户机：-vnc 宿主机IP:2,reverse

**VNC 窗口的标题栏中显示**
-name 设置显示方式

### 7.2 -sdl 参数 ##

使用 SDL 方式显示客户机。

### 7.3 -vga 参数 ##
设置客户机中的 VGA 显卡类型，默认为 ”-vga cirrus” ，默认会为客户机模拟出 Cirrus Logic GD5446 显卡。“-vga std”会为客户机模拟出带有 Bochs VBE 扩展的标准 VGA显卡，而“-vga none” 参数是不为客户机分配 VGA 卡，会让 VNC或SDL都没有任何显示。

### 7.4 -nographic 参数 ##
完全关闭 QEMU 的图形化界面输出，从而让 QEMU 在模式下完全成为简单的命令行工具。而QEMU中模拟产生的串口被重定向到了当前的控制台中，所以如果在客户机中对其内核进行配置从而让内核的控制台输出重定向到串口后，就依然可以在非图形模式下管理客户机系统。在非图形模式下，使用 Ctrl+a h(按Ctrl+a 之后，再按h 键) 组合键，可以获得终端命令的帮助

qemu-system-x86_64 -enable-kvm -m 8192 -smp 1 -hda /home/berta/ia32e_rhel7u2_kvm.img -cpu kvm64 -nographic

新的可以采用
-display sdl
-display vnc
-display none
-display curses

## 8. 其它参数

### 常用参数
(1) 鼠标飘移问题

    Xen: 配置文件添加如下两项
       usb=1
       usbdevice='tablet'
    
    KVM:
        -usb -usbdevice tablet
    在最新的QEMU中， 也可以使用 “-device piix3-usb-uhci -device usb-tablet”参数。目前QEMU社区也主要推动使用功能丰富的 “-device” 参数来替代以前的一些参数（如：-usb等）。

### 不常用参数
KVM

(1) -daemonize 参数
     在启动时让 qemu 作为守护进程在后台运行。

(2) -enable-kvm 参数
     打开 KVM 虚拟化的支持，在纯 QEMU 中，默认是没有打开的。

(3) -soundhw
     开启声卡硬件的支持
     “-soundhw ?”  查看有效的声卡的种类 ，如"-soundhw ac97"

(4) -name
     设置客户机的名词可用于在某宿主机上唯一标识该客户机

(5) -uuid
     UUID 是按照 8-4-4-4-12个数分布的32个十六进制数字

(6) -rtc 设置 RTC 开始时间和时钟类型
     -rtc [base=utc|localtime|date][,clock=host|rt|vm][,driftfix=none|slew]
         base 用于设置客户机的实时时钟开始数据，默认为 utc
         clock 设置实时时钟的类型。
                默认情况下是 clock=host，表示由宿主机的系统时间来驱动
                clock=rt 则表示将客户机和宿主机的时间进行隔离，而不进行校对
                clock=vm 当客户机暂停时候，客户机时间不会继续向前计时。
        driftfix 用于设置是否进行时间漂移的修复，slew 修复，默认为none 不修复。

(7) -no-reboot 和 -no-shutdown 参数
     "-no-reboot" 参数，让客户机在执行重启操作时，在系统关闭后就退出 qemu-kvm 进程，而不会再启动客户机。
     "-no-shutdown" 参数，让客户机执行关机操作时，在系统关闭后，不退出 qemu-kvm 进程，而是保持这个进程
存在，它的 QEMU monitor 依然可以使用。在需要的情况下，这就允许在关机后切换到 monitor 中将磁盘镜像的改
变提交到真正的镜像文件中。

(8) -loadvm 加载快照状态
     "-loadvm mysnapshot" 在 qemu-kvm 启动客户机时即加载系统的某个快照，这于 QEMU monitor 中的 loadvm 命
令功能相似。

(9) -pidfile 保存进程 ID 到文件中。
    "-pidfile qemu-pidfile" 保存 qemu-kvm 进程的 PID 文件到 qemu-pidfile 中，这对在某些脚本中对该进程继续做处
理提供了便利（如设置该进程的 CPU 亲和性，监控该进程的运行状态）。

(10) -nodefaults 不创建默认的设备
    在默认情况下，qemu-kvm 会为客户机配置一些默认的设备，如串口、并口、虚拟控制台、monitor 设备、VGA
显卡等。该参数可以完全禁止默认创建的设置，而仅仅使用命令行中显式指定的设备。

(11) -readconfig 和 -writeconfig 参数
    “-readconfig guest-config” 参数从文件中读取客户机设备的配置（注意仅仅是设备的配置信息，不包括CPU、内存
之类的信息）。当 qemu-kvm 命令行参数的长度超过系统允许的最长参数的个数时，qemu-kvm 将会遇到错误信息
“arg list too long” ，这时如果将需要的配置写到文件中，使用 “-readconfig" 参数来读取配置，就可以避免参数过长的
问题。在Linux系统中可以用 “getconf ARG_MAX” 命令查看系统能支持的命令行参数的字符个数。
    “-writeconfig guest-config” 参数表示将客户机中设备的配置写到文件中；“-writeconfig ” 参数则会将设备的配置打
印在标准输出中。保存好的配置文件，可以用于刚才介绍的 “-readconfig guest-config” 参数。笔者保存下来的一个示
例设备配置文件如下：

    [drive]
        media = "disk"
        index = "0"
        file = "rhel6u3.img"
    [net]
        type = "nic"
    [net]
        type = "tap"
    [cpudef]
        name = "Conroe"
        level = "2"
        vendor = "GenuineIntel"
        family="6"
    <!-- 以下省略数十行信息 -->

(12) Linux 或多重启动相关的参数
    qemu-kvm 提供了一些参数，可以让用户不用安装系统到磁盘上即可启动 Linux 或多重启动的内核，这个功能可以用于
进行早期调试或测试各种不同的内核。

    a. -kernel bzImage
        使用 bzImage 作为客户机内核镜像。这个内核可以是一个普通 Linux 内核或多重启动的格式中的内核镜像。
    b. -append cmdline
        使用 cmdline 作为内核附加的命令选项。
    c. -initrd file
        使用 file 作为初始化启动时的内存盘。
    d. -initrd "file1 arg=foo,file2"
        仅使用多重启动中，使用 file1 和 file2 作为模块，并将 arg=foo 作为第一个模块的 file1.
    e. -dtb file
        使用 file 文件作为设备树二进制 dtb(device tree binary) 镜像，在启动时将其传递给客户机内核。

(13) 调试相关参数

    qemu-kvm 中也有很多和调试相关的参数，下面简单介绍其中的几个参数。

    a. -singlestep
        以单步执行的模式运行 QEMU 模拟器。
    b. -S
        在启动时并不启动 CPU，需要在 monitor 中运行 c 或 cont 命令才能继续运行，它可以配合 -gdb 参数一起使用，启动后，让gdb 远程连接到 qemu-kvm 上，然后再继续运行。
    c. -gdb dev
        运行GDB服务端(gdbserver)，等待GDB连接到dev 设备上。典型的连接可能是给予 TCP 协议的，当然也可能是基于 UDP 协议、虚拟终端(pty)，甚至是标准输入输出。
        在 qemu-kvm 命令行中使用 TCP 方式的 -gdb 参数，示例如下：
        # qemu-system-x86_64 -kernel vmlinuz-3.6 -initrd initrd-3.6.img -gdb tcp::1234 -S
        在本机的 GDB 中可以运行如下命令连接到 qemu-kvm 运行的内核上去，当然如果是远程调试就需要添加一些网络 IP地址的参数。
        (gdb) target remote :1234

    d. -s
        -s 参数是 "-gdb tcp::1234" 的简写表达方式，即在 TCP 1234 端口打开一个 GDB 服务器。
    e. -d
        将 QEMU 的日志保存在 /tmp/qemu.log 中，以便调试时查看日志。
    f. -D logfile
        将 QEMU 的日志保存到 logfile 文件中（而不是 -d 参数指定的 /tmp/qemu.log）中。
