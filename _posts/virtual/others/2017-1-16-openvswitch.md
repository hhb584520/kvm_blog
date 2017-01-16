# 1. 介绍 #
## 1.1 提供功能 ##
- Standard 802.1Q VLAN model with trunk and access ports
- NIC bonding with or without LACP on upstream switch
- NetFlow, sFlow(R), and mirroring for increased visibility
- QoS (Quality of Service) configuration, plus policing
- Geneve, GRE, VXLAN, STT, and LISP tunneling
- 802.1ag connectivity fault management
- OpenFlow 1.0 plus numerous extensions
- Transactional configuration database with C and Python bindings
- High-performance forwarding using a Linux kernel module

## 1.2 官网 ##
http://openvswitch.org/

# 2. 环境搭建 #
## 2.1 安装 ##

- 解压openvswitch包

	tar -zxvf openvswitch-1.2.2.tar.gz;  
	cd openvswitch-1.2.2;

- 生成rhel6的内核模块文件
	
    ./boot.sh;  
    ./configure; make dist  
    cp openvswitch-1.2.2.tar.gz /root/rpmbuild/SOURCES/  
    rpmbuild -bb rhel/openvswitch-kmod-rhel6.spec  
    rpm -ivh /root/rpmbuild/RPMS/x86_64/kmod-openvswitch-1.2.2-1.el6.x86_64.rpm

- 加载模块

	modprobe openvswitch_mod
	modprobe brcompat_mod

- 生成openvswitch的相关命令，并将命令可执行文件拷贝到/bin

	./configure;
	make
	make install
	cp /usr/local/bin/ovs* /bin/

# 3.配置 Openvswitch
## 3.1 配置 ##

- 创建openvswitch数据库
	
	mkdir -p /usr/local/etc/openvswitch;
	ovsdb-tool create /usr/local/etc/openvswitch/conf.db vswitchd/vswitch.ovsschema

- 启动openvswitch数据库
	ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
                 --remote=db:Open_vSwitch,manager_options \
                 --private-key=db:SSL,private_key \
                 --certificate=db:SSL,certificate \
                 --bootstrap-ca-cert=db:SSL,ca_cert \
                 --pidfile --detach

- 启动openvswitch交换机服务

	ovs-vswitchd --pidfile –detach

- 初始openvswitch化交换机

	ovs-vsctl --no-wait init

- 启动openvswitch交换机和Linux网桥兼容服务

	ovs-brcompatd --pidfile –detach

- 创建一个交换机，并将em1接口划分到交换机中
	
	    注意：和em1相连的交换机端口需要配置成trunk模式
	    brctl addbr br0
	    brctl addif br0 em1
	    也可以使用如下命令
	    #/usr/local/bin/ovs-vsctl del-br br0
	    #/usr/local/bin/ovs-vsctl add-br br0
	    #/usr/local/bin/ovs-vsctl add-port br0 em1

- 使用命令ovs-vsctl show可以看到结果

	[root@dell4 ~]# ovs-vsctl show

因为和linux网桥兼容，使用brctl show命令，也可以看到
[root@dell4 ~]# brctl show

为了让openvswitch相关服务开机能够启动，编辑一个脚本，放置到/etc/rc.local中，内容如下：

	[root@dell4 ~]# cat start_openvswitch.sh
	rmmod bridge
	modprobe openvswitch_mod
	modprobe brcompat_mod
	/usr/local/sbin/ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock \
	                    --remote=db:Open_vSwitch,manager_options \
	                    --private-key=db:SSL,private_key \
	                    --certificate=db:SSL,certificate \
	                    --bootstrap-ca-cert=db:SSL,ca_cert \
	                    --pidfile --detach

 
	#/usr/local/sbin/ovs-brcompatd --appctl=/usr/local/bin/ --detach
	/usr/local/sbin/ovs-vswitchd --pidfile --detach
	/usr/local/bin/ovs-vsctl --no-wait init
	/usr/local/sbin/ovs-brcompatd --pidfile --detach
	 
	#/usr/local/bin/ovs-vsctl del-br br0
	#/usr/local/bin/ovs-vsctl add-br br0
	#/usr/local/bin/ovs-vsctl add-port br0 em1
	ifconfig br0 up
	ifconfig br0 172.16.1.160 netmask 255.255.255.0
	route add -net 0.0.0.0 netmask 0.0.0.0 gw 172.16.1.1

## 3.2 让虚拟机使用openvswitch ##
新建一台虚拟机，添加网卡的时候如下图操作：

或者可以编辑xml文件，网卡部分如下：
 
	<interface type='bridge'>
      <mac address='52:54:00:b4:46:a5'/>
      <source bridge='br0'/>
      <model type='e1000'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

## 3.3  Openvswitch配置ACL ##
 
Openswitch的acl通过ofctl工具配置
命令如下：


- 添加规则
	add-flow 交换机规则
	add-flow 交换机 <规则文件
	add-flows 交换机规则文件

- 修改规则
	mod-flows交换机规则
	mod-flows 交换机 <规则文件

- 删除规则
	del-flows交换机规则
	del-flows 交换机 <规则文件

- 替换规则文件
	Replace-flows 交换机 规则文件

例子

	ovs-ofctl add-flow br0 dl_src=52:54:00:aa:bb:cc,tp_dst=80,idle_timeout=0,actions=normal
	ovs-ofctl add-flow br0 dl_dst=52:54:00:aa:bb:cc,tp_src=80,idle_timeout=0,actions=normal
	ovs-ofctl add-flow br0 dl_src=52:54:00:aa:bb:cc,tp_dst=53,idle_timeout=0,actions=normal
	ovs-ofctl add-flow br0 dl_dst=52:54:00:aa:bb:cc,tp_src=53,idle_timeout=0,actions=normal
	ovs-ofctl add-flow br0 dl_src=52:54:00:aa:bb:cc,tp_dst=67,idle_timeout=0,actions=normal
	ovs-ofctl add-flow br0 dl_dst=52:54:00:aa:bb:cc,tp_dst=68,idle_timeout=0,actions=normal
 
语法说明

	In_port=端口 #端口可以通过show命令查看
	dl_vlan=VLAN
	更详细的说明可以查看文档，或者man
 
 
查看交换机配置台信息

	ovs-ofctl show br0
	OFPT_FEATURES_REPLY (xid=0x1): ver:0x1, dpid:0000001b21890bdc
	n_tables:1, n_buffers:256
	features: capabilities:0x87, actions:0xfff
	 3(dummy0): addr:26:ed:1a:ad:57:68
	     config:     0
	     state:      0
	 10(tap0): addr:32:a9:03:61:77:e8
	     config:     0
	     state:      0
	     current:    10MB-FD COPPER
	 15(p1p2): addr:00:1b:21:89:0b:dd
	     config:     0
	     state:      0
	     current:    1GB-FD COPPER AUTO_NEG
	     advertised: 10MB-HD 10MB-FD 100MB-HD 100MB-FD 1GB-FD COPPER AUTO_NEG
	     supported:  10MB-HD 10MB-FD 100MB-HD 100MB-FD 1GB-FD COPPER AUTO_NEG
	 16(p1p1): addr:00:1b:21:89:0b:dc
	     config:     0
	     state:      0
	     current:    1GB-FD COPPER AUTO_NEG
	     advertised: 10MB-HD 10MB-FD 100MB-HD 100MB-FD 1GB-FD COPPER AUTO_NEG
	     supported:  10MB-HD 10MB-FD 100MB-HD 100MB-FD 1GB-FD COPPER AUTO_NEG
	 LOCAL(br0): addr:00:1b:21:89:0b:dc
	     config:     PORT_DOWN
	     state:      LINK_DOWN
	OFPT_GET_CONFIG_REPLY (xid=0x3): frags=normal miss_send_len=0
 
查看已经配置的acl信息
 
	ovs-ofctl dump-flows br0
	NXST_FLOW reply (xid=0x4):
	 cookie=0x0, duration=554.927s, table=0, n_packets=0, n_bytes=0, dl_dst=52:54:00:aa:bb:cc actions=NORMAL
	 cookie=0x0, duration=186846.192s, table=0, n_packets=2936225, n_bytes=2819308581, priority=0 actions=NORMAL
	 cookie=0x0, duration=555.702s, table=0, n_packets=0, n_bytes=0, dl_src=52:54:00:aa:bb:cc actions=NORMAL

## 3.4  Openvswitch 配置端口镜像 ##
 
1)#Create a dummy interface that will recieve mirrored packets

	modprobe dummy
	ip link set up dummy0
	modprobe dummy
	#Add the dummy interface to the bridge in use
 
2)添加端口到openvswitch中

	ovs-vsctl add-port br0 dummy0

3)做端口镜像
	ovs-vsctl -- --id=@m create mirror name=mirror0 -- add bridge br0 mirrors @m
	 
	ovs-vsctl list port dummy0
	d3427810-8e68-40af-99c0-8cb935af9882
	ovs-vsctl set mirror mirror0 \
	output_port=d3427810-8e68-40af-99c0-8cb935af9882
	 
	ovs-vsctl set mirror mirror0 select_all=1

测试

	tcpdump –i dummy0
 
## 3.5  Openvswitch 配置qos ##
 
测试环境如下
网络设备 cisco 2960s
服务器 dell r610
操作系统 fedora 15+update
服务器上添加一块intel 82571双端口的网卡，分别接交换机的1口，2口
 
配置端口tap0 最大速度不超过100M
ovs-vsctl -- set port tap0  qos=@newqos \
-- --id=@newqos create qos type=linux-htb other-config:max-rate=100000000 queues=0=@q0,1=@q1 \
-- --id=@q0 create queue other-config:min-rate=100000000 other-config:max-rate=100000000 \
-- --id=@q1 create queue other-config:min-rate=500000000 \
 
清除tap0上的qos策略
ovs-vsctl -- destroy QoS tap0 -- clear Port tap0 qos
 
查看交换机br0端口信息
ovs-ofctl show br0
ovs-dpctl show
 
## 3.6  Openvswitch配置端口绑定 ##
 
测试环境如下
网络设备 cisco 2960s
服务器 dell r610
操作系统 fedora 15+update
服务器上添加一块intel 82571双端口的网卡，分别接交换机的1口，2口
配置如下
交换机配置

	interface Port-channel1
	 switchport trunk allowed vlan 200
	 switchport mode trunk
	!
	interface FastEthernet0
	 no ip address
	 shutdown
	!
	interface GigabitEthernet0/1
	 switchport trunk allowed vlan 200
	 switchport mode trunk
	 channel-protocol lacp
	 channel-group 1 mode active
	!
	interface GigabitEthernet0/2
	 switchport trunk allowed vlan 200
	 switchport mode trunk
	 channel-protocol lacp
	 channel-group 1 mode active
	!

服务器配置

	ovs-vsctl add-bond br0 pc p1p1 p1p2
	ovs-vsctl -- set port  pc lacp=paasive

在交换机上查看
 
	2960s-250#  sh int port-channel 1
	Port-channel1 is up, line protocol is up (connected)
	  Hardware is EtherChannel, address is 88f0.77c0.8f01 (bia 88f0.77c0.8f01)
	  MTU 1500 bytes, BW 2000000 Kbit, DLY 10 usec,
	     reliability 255/255, txload 1/255, rxload 1/255
	  Encapsulation ARPA, loopback not set
	  Keepalive set (10 sec)
	  Full-duplex, 1000Mb/s, link type is auto, media type is unknown
	  input flow-control is off, output flow-control is unsupported
	  Members in this channel: Gi0/1 Gi0/2
	  ARP type: ARPA, ARP Timeout 04:00:00
	  Last input never, output 00:00:00, output hang never
	  Last clearing of "show interface" counters never
	  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
	  Queueing strategy: fifo
	  Output queue: 0/40 (size/max)
	  5 minute input rate 1000 bits/sec, 1 packets/sec
	  5 minute output rate 2000 bits/sec, 2 packets/sec
	     1680 packets input, 168447 bytes, 0 no buffer
	     Received 90 broadcasts (52 multicasts)
	     0 runts, 0 giants, 0 throttles
	     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored
	     0 watchdog, 52 multicast, 0 pause input
	     0 input packets with dribble condition detected
	     2293 packets output, 211880 bytes, 0 underruns
	     0 output errors, 0 collisions, 8 interface resets
	     0 babbles, 0 late collision, 0 deferred
	     0 lost carrier, 0 no carrier, 0 PAUSE output
	     0 output buffer failures, 0 output buffers swapped out
可以看到portchannel已经起来了

## 3.7  openvswitch+kvm vlan功能的使用 ##
要在kvm+openvswitch环境中使用vlan功能，只能使用qemu的命令行来创建虚拟机，假设需要使虚拟机的网络接口在vlan 200中，操作步骤如下：
 
- 创建两个脚本

		cat > /etc/ovs-ifup << EOF
		#!/bin/sh
		switch='br0'
		/sbin/ifconfig \$1 0.0.0.0 up
		ovs-vsctl add-port \${switch} \$1 tag=200
		EOF
		 
		cat > /etc/ovs-ifdown << EOF
		#!/bin/sh
		switch='br0'
		/sbin/ifconfig \$1 0.0.0.0 down
		ovs-vsctl del-port \${switch} \$1
		EOF

- 创建em1接口的一个自接口配置文件ifcfg-em1.200，内容如下：

		cat ifcfg-em1.201
		DEVICE=em1.201
		ONBOOT=yes
		BOOTPROTO=none
		TYPE=Ethernet
		VLAN=yes

- 启动虚拟机

		/usr/libexec/qemu-kvm \
		-name w2k303 \
		-smp 1,1 \
		-m 4096 \
		-drive file=/data/w2k303,if=virtio,cache=none,format=qcow2,index=0,boot=on \
		-net br2,script=/etc/openvswitch/ovs-ifup,downscript=/etc/openvswitch/ovs-ifdown