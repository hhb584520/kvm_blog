# 其它配置 #
## 1. xl 和 qemu-system-x86_64 的帮助

### 1.1 XL ###

	1. 下载Xen的源码
	2. 执行编译命令
	   make docs && make install-docs
	3. 查看xl 配置文件的参数 man xl.cfg

	https://xenbits.xen.org/docs/unstable/man/xl.cfg.5.html

### 1.2 Qemu-system-x86_64 ###
    
	qemu-system-x86_64 --help
    qemu-system-x86_64 -cpu help 

	https://wiki.archlinux.org/index.php/QEMU_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)
 
## 2. Network
### 2.1 bridge
#### 2.1.1 添加接口到网桥
- 添加 br0 这个 bridge
  
	brctl addbr br0

- 将 br0 与 eth0 绑定起来     
    
	brctl addif br0 eth0

- 将 br0 设置为启用 STP 协议
    
	brctl stp br0 on

    注：在这里使用 STP 主要是为了避免在建有 bridge 的以太网 LAN 中出现环路。如果不打开 STP，则可能出现数据链路层的环路，从而导致建有 bridge 的主机网络不畅通。

- 将 eth0 的 IP 设置为0
    
	dhclient br0

- 参看路由表是否正常配置
    
	route

#### 2.1.2 删除 virbr0
安装 KVM 后都会发现网络接口里多了一个叫做 virbr0 的虚拟网络接口
一般情况下，虚拟网络接口virbr0用作nat，以允许虚拟机访问网络服务，但nat一般不用于生产环境。我们可以使用以下方法删除virbr0

- 先使用virsh net-list查看所有的虚拟网络：

		[root~]# virsh net-list               //列出kvm虚拟网络

- 卸载与删除virbr0虚拟网络接口

		$ virsh net-destroy default    //重启libvirtd服务后会恢复  
		$ virsh net-undefine default   //彻底删除，重启系统后也不会恢复
 

#### 2.1.3 恢复virbr0

- 其实上面的做法，其实就是删除了/var/lib/libvirt/network/default.xml文件，

  恢复的方法，我们需要从另一台kvm宿主机上把default.xml文件复制过来，并将下面的<uuid>标签对及<mac>标签去掉。

	<!--
	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE 
	OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
	  virsh net-edit default
	or other application using the libvirt API.
	-->
	
	<network>
	  <name>default</name>
	  <uuid>ef1080c8-61d0-421e-8358-0568afb21093</uuid>
	  <forward mode='nat'/>
	  <bridge name='virbr0' stp='on' delay='0' />
	  <mac address='52:54:00:01:59:93'/>
	  <ip address='192.168.122.1' netmask='255.255.255.0'>
	    <dhcp>
	      <range start='192.168.122.2' end='192.168.122.254' />
	    </dhcp>
	  </ip>
	</network>

- 从一个xml文件定义default网络，执行如下命令：


		$ virsh net-define /var/lib/libvirt/network/default.xml   //从一个default.xml文件定义(但不开始)一个网络


- 设置virbr0自动启动，执行如下命令：

		$ virsh net-start default           //开始一个(以前定义的default)不活跃的网络,执行后ifconfig可见virbr0
		$ virsh net-autostart default       //执行后Autostart外会变成yes


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

    



