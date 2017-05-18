# 配置文件 #
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

    可以使用下面命令查看
        info cpus 
        ps -efL | grep qemu   # 其中 -L可以查看线程 ID。

### 2.2 CPU 模型
#### 2.2.1 KVM
- 查看当前的 QEMU 支持的所有 CPU 模型（cpu_model, 默认的模型为qemu64）
        
	qemu-system-x86_64 -cpu ?
	其中加了 [] ，如 qemu64, kvm64 等CPU模型是 QEMU命令中原生自带 (built-in) 的，现在所有的定义都放在 target-i386/cpu.c 文件中

- 尽可能多地将物理CPU信息暴露给客户机
        
	-cpu host

- 改变 qemu64 类型CPU的默认类型
        
	-cpu qemu64,model=13

- 可以用一个 CPU模型作为基础，然后用“+”号将部分的CPU特性添加到基础模型中去
        
	-cpu qemu64,+avx

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
 

## 2. Network
### 2.1 虚拟机网桥配置 ###
#### 2.1.1 KVM ####
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

#### 2.1.2 XEN

配置文件添加如下项
	
	vif = [ 'type=ioemu, mac=00:16:3e:14:e4:d5, bridge=xenbr0' ]

### 2.2 虚拟直通网卡配置
**直通网卡**

qemu-system-x86_64 -enable-kvm -m 4096 -monitor pty -smp 64 -no-acpi -drive file=/share/xvs/var/tmp-img_CPL_CPU_288VCPU_4_1483531055_1,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -device vfio-pci,host=${bdf} -net none –daemonize

### 2.3 参数说明
    
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


## 3. 鼠标飘移问题
    Xen: 配置文件添加如下两项
       usb=1
       usbdevice='tablet'
    
    KVM:
        -usb -usbdevice tablet
    在最新的QEMU中， 也可以使用 “-device piix3-usb-uhci -device usb-tablet”参数。目前QEMU社区也主要推动使用功能丰富的 “-device” 参数来替代以前的一些参数（如：-usb等）。

## 4. 其它参数
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

## 5. VNC的使用 ##
   普通VNC使用
   启动虚拟机的参数 -vnc :2
   客户机：vncviewer :2

   反转 VNC
    宿主机：vncviewer -listen :2
[root@knl2 ~]# vncviewer -listen 2
TigerVNC Viewer 64-bit v1.3.1 (20150902)
Built on Sep  2 2015 at 11:19:20
Copyright (C) 1999-2011 TigerVNC Team and many others (see README.txt)
See http://www.tigervnc.org for information on TigerVNC.

Mon Jun 20 23:28:11 2016
 main:        Listening on port 2

    客户机：-vnc 宿主机IP:2,reverse
    

## 6. 启动虚拟机的例子 #
    
qemu-system-x86_64 -enable-kvm -m 2048 -smp 4  -device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup -drive file=/share/xvs/var/rhel7.qcow,if=none,id=virtio-disk0 -device virtio-blk-pci,drive=virtio-disk0 -monitor pty -cpu kvm64

qemu-ifup-NAT
	#!/bin/sh
	# qemu-ifup script for QEMU/KVM with NAT network mode
	
	# set your bridge name
	BRIDGE=virbr0
	
	# Network information
	NETWORK=192.168.122.0
	NETMASK=255.255.255.0
	
	#GATEWAY for internal guests is the bridge in host
	GATEWAY=192.168.122.1
	DHCPRANGE=192.168.122.2,192.168.122.254
	
	# Optionally parameters to enable PXE support
	TFTPROOT=
	BOOTP=
	
	function check_bridge()
	{
	    if brctl show | grep "^$BRIDGE" &> /dev/null; then
	        return 1
	    else
	        return 0
	    fi
	}
	
	function create_bridge()
	{
	    brctl addbr "$BRIDGE"
	    brctl stp  "$BRIDGE" on
	    brctl setfd  "$BRIDGE" 0
	    ifconfig  "$BRIDGE"  "$GATEWAY" netmask  "$NETMASK" up
	}
	
	function enable_ip_forward()
	{
	    echo 1 > /proc/sys/net/ipv4/ip_forward
	}
	
	function add_filter_rules()
	{
	    iptables -t nat -A POSTROUTING -s "$NETWORK"/"$NETMASK" \
	        ! -d  "$NETWORK"/"$NETMASK" -j MASQUERADE
	}
	
	function start_dnsmasq()
	{
	    # don't run dnsmasq repeatedly
	    ps -ef | grep "dnsmasq" | grep -v "grep" &> /dev/null
	    if [ $? -eq 0 ]; then
	        echo "Warning:dnsmasq is already running."
	        return 1
	    fi
	
	    dnsmasq \
	        --strict-order  \
	        --except-interface=lo  \
	        --interface=$BRIDGE  \
	        --listen-address=$GATEWAY  \
	        --bind-interfaces  \
	        --dhcp-range=$DHCPRANGE  \
	        --conf-file=""  \
	        --pid-file=/var/run/qemu-dhcp-$BRIDGE.pid  \
	        --dhcp-leasefile=/var/run/qemu-dhcp-$BRIDGE.leases  \
	        --dhcp-no-override  \
	        ${TFTPROOT:+"--enable-tftp"}  \
	        ${TFTPROOT:+"--tftp-root=$TFTPROOT"}  \
	        ${BOOTP:+"--dhcp-boot=$BOOTP"}
	}
	
	function setup_bridge_nat()
	{
	    check_bridge  "$BRIDGE"
	    if [ $? -eq 0 ]; then
	        create_bridge
	    fi
	    enable_ip_forward
	    add_filter_rules  "$BRIDGE"
	    start_dnsmasq  "$BRIDGE"
	}
	
	# need to check  $1 arg before setup
	if [ -n "$1" ]; then
	    setup_bridge_nat
	    ifconfig "$1" 0.0.0.0 up
	    brctl addif "$BRIDGE" "$1"
	    exit 0
	else
	    echo "Error: no interface specified."
	    exit 1
	fi
	
	qemu-ifdown-NAT
	#!/bin/sh
	# qemu-ifdown script for QEMU/KVM with NAT network mode
	
	# set your bridge name
	BRIDGE=virbr0
	
	# need to check  $1 arg before setup
	if [ -n "$1" ]; then
	    echo "Tearing down network bridge for $1"
	    ip link set $1 down
	    brctl delif "$BRIDGE" $1
	    ip link set "$BRIDGE"  down
	    brctl delbr "$BRIDGE" 
	    iptables -t nat -F
	    exit 0
	else
	    echo "Error: no interface specified."
	    exit 1
	fi

    



