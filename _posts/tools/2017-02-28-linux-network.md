# 1. rp_filter 配置 #

某台机器有两个网卡，安装 Linux 系统，两个网卡的 IP 地址分别为 eth0（172.16.1.1/24） 和 eth1（172.16.2.1/24），缺省网关为 172.16.1.254， 没有用到策略路由。两个网卡的网络连接都正常，即分别 ping 该网卡所在局域网 内的地址都能正常收到回应。网关的设置也没有问题。

	# ip addr
	1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
	    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
	    inet 127.0.0.1/8 scope host lo
	       valid_lft forever preferred_lft forever
	2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
	    link/ether 00:07:e9:1a:b3:5a brd ff:ff:ff:ff:ff:ff
	    inet 172.16.1.0/24 brd 172.16.1.255 scope global eth0
	       valid_lft forever preferred_lft forever
	3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
	    link/ether 00:1e:4f:ea:f2:2e brd ff:ff:ff:ff:ff:ff
	    inet 172.16.2.0/24 brd 172.16.2.255 scope global eth1
	       valid_lft forever preferred_lft forever
	# ip route
	default via 172.16.1.254 dev eth0  metric 3
	172.16.1.0/24 dev eth0  proto kernel  scope link  src 172.16.1.1
	172.16.2.0/24 dev eth1  proto kernel  scope link  src 172.16.2.1
	127.0.0.0/8 via 127.0.0.1 dev lo

现在的问题是在 172.16.1.0/24 网段内的一台机器上（假设 ip 是 172.16.1.2） ping 172.16.2.1 时却得不到回应。在 eth1 上用 tcpdump 抓包能看到 ICMP 请 求包，但两个网卡上都没有看到 ICMP 回应包。其实仔细分析路由表能看到，由 172.16.1.2 到 172.16.2.1 的 ICMP 包会经过网关（172.16.1.254）后转发到 eth1 上，但 172.16.2.1 回应请求包时查看自身的路由表时发现 172.16.1.2 和 其 eth0 是在同一局域网内，用不着再经过网关转发，即 ICMP 请求和回应包的路径 是不一样的。Linux 网络相关参数里正好有一个参数是控制这种行为的，即 rp_filter。 相应的文档如下：
rp_filter - INTEGER

    0 - No source validation.
    1 - Strict mode as defined in RFC3704 Strict Reverse Path
        Each incoming packet is tested against the FIB and if the interface
        is not the best reverse path the packet check will fail.
        By default failed packets are discarded.
    2 - Loose mode as defined in RFC3704 Loose Reverse Path
        Each incoming packet's source address is also tested against the FIB
        and if the source address is not reachable via any interface
        the packet check will fail.

    Current recommended practice in RFC3704 is to enable strict mode
    to prevent IP spoofing from DDos attacks. If using asymmetric routing
    or other complicated routing, then loose mode is recommended.

    The max value from conf/{all,interface}/rp_filter is used
    when doing source validation on the {interface}.

    Default value is 0. Note that some distributions enable it
    in startup scripts.

上面的问题在设置回应包使用的网卡 eth1 或 ‘all’ 对应的 rp_filter 为 0 或 2 之后即可解决。

	sysctl -w net.ipv4.conf.all.rp_filter=2
或

	sysctl -w net.ipv4.conf.eth1.rp_filter=2
。
对没有所谓的 multihoming 的主机，rp_filter 的值设置为 1 不会有任何问题。如 果需要在系统启动时即生效该配置，修改 /etc/sysctl.conf 或新增一个文件如 /etc/sysctl.d/rp_filter.conf 增加如下内容即可：

	net.ipv4.conf.default.rp_filter = 2
	net.ipv4.conf.all.rp_filter = 2

补充，如果设置了 eth1 的 log_martians 参数 （sysctl -w net.ipv4.conf.eth1.log_martians=1），

	dmesg

可以看到如下信息：

	IPv4: martian source 172.16.2.1 from 172.16.1.2, on dev eth1
	ll header: 00000000: 00 07 e9 1a b3 5a 38 22 d6 b5 30 c7 08 00        .....Z8"..0...
	log_martians 的文档如下：
	log_martians - BOOLEAN
	    Log packets with impossible addresses to kernel log.
	    log_martians for the interface will be enabled if at least one of
	    conf/{all,interface}/log_martians is set to TRUE,
	    it will be disabled otherwise


# 2. Linux 下 802.1Q VLAN 实现配置工具 #  
## 2.1 编译内核，使内核支持802.1Q VLAN ##

下载Linux2.4.20内核：http://www.kernel.org/pub/linux/kernel/v2.4/linux-2.4.20.tar.bz2 

cp linux-2.4.20.tar.bz2 /usr/src 

tar -jxvf linux-2.4.20.tar.bz2 

ln -s linux-2.4.20 linux 

cd linux 

make menuconfig 

Networking options ---><M> 802.1Q VLAN Support (可以编译为模块或编译进内核。) 

……………… 

编译完成后启用新内核。 

## 2.2 VLAN的配置  ##

下载VLAN配置工具软件：http://www.candelatech.com/~greear/vlan/vlan.1.7m.tar.gz 

tar -zxvf vlan.1.7m.tar.gz 

cd vlan 

cp vconfig /usr/sbin 

注： 如果需要支持基于MAC地址划分的VLAN，需要给内核打补丁（vlan.1.7m.tar.gz中有），并将macvlan_config拷贝到/sbin下，用macvlan_config命令来进行VLAN配置。 

(1)、创建VLAN10、VLAN12、VLAN13 

vconfig add eth0 10 

vconfig add eth0 12 

vconfig add eth0 13 

(2)、为接口设置IP地址： 

ip address add 192.168.5.3/28 dev eth0.12 （DMZ区域的网关） 

ip address add 192.168.10.1/24 dev eth0.13 （Classroom的网关） 

ip address add 192.168.9.1/27 dev eth0.10 （office的网关） 

ip link set dev eth0.12 up （启用设备） 
ip link set dev eth0.10 up 
ip link set dev eth0.13 up

# 参考资料 #
http://blog.clanzx.net/2013/08/22/rp_filter.html