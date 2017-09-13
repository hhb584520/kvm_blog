# 1. 网络性能测试介绍

测量网络性能的五项指标是：
可用性（availability）
响应时间（response time）
网络利用率（network utilization）
网络吞吐量（network throughput）
网络带宽容量（network bandwidth capacity）

## 1.1 可用性
测试网络性能的第一步是确定网络是否正常工作，最简单的方法是使用 ping 命令。通过向远端的机器发送 icmp echo request，并等待接收 icmp echo reply 来判断远端的机器是否连通，网络是否正常工作。Ping 命令有非常丰富的命令选项，比如 -c 可以指定发送 echo request 的个数，-s 可以指定每次发送的 ping 包大小。

网络设备内部一般有多个缓冲池，不同的缓冲池使用不同的缓冲区大小，分别用来处理不同大小的分组（packet）。例如交换机中通常具有三种类型的包缓冲：一类针对小的分组，一类针对中等大小的分组，还有一类针对大的分组。为了测试这样的网络设备，测试工具必须要具有发送不同大小分组的能力。Ping 命令的 -s 就可以使用在这种场合。

## 1.2 响应时间
Ping 命令的 echo request/reply 一次往返所花费时间就是响应时间。有很多因素会影响到响应时间，如网段的负荷，网络主机的负荷，广播风暴，工作不正常的网络设备等等。
在网络工作正常时，记录下正常的响应时间。当用户抱怨网络的反应时间慢时，就可以将现在的响应时间与正常的响应时间对比，如果两者差值的波动很大，就能说明网络设备存在故障。

## 1.3 网络利用率
网络利用率是指网络被使用的时间占总时间（即被使用的时间+空闲的时间）的比例。比如，Ethernet 虽然是共享的，但同时却只能有一个报文在传输。因此在任一时刻，Ethernet 或者是 100% 的利用率，或者是 0% 的利用率。
计算一个网段的网络利用率相对比较容易，但是确定一个网络的利用率就比较复杂。因此，网络测试工具一般使用网络吞吐量和网络带宽容量来确定网络中两个节点之间的性能。

## 1.4 网络吞吐量
网络吞吐量是指在某个时刻，在网络中的两个节点之间，提供给网络应用的剩余带宽。
网络吞吐量可以帮组寻找网络路径中的瓶颈。比如，即使 client 和 server 都被分别连接到各自的 100M Ethernet 上，但是如果这两个 100M 的Ethernet 被 10M 的 Ethernet 连接起来，那么 10M 的 Ethernet 就是网络的瓶颈。
网络吞吐量非常依赖于当前的网络负载情况。因此，为了得到正确的网络吞吐量，最好在不同时间（一天中的不同时刻，或者一周中不同的天）分别进行测试，只有这样才能得到对网络吞吐量的全面认识。
有些网络应用程序在开发过程的测试中能够正常运行，但是到实际的网络环境中却无法正常工作（由于没有足够的网络吞吐量）。这是因为测试只是在空闲的网络环境中，没有考虑到实际的网络环境中还存在着其它的各种网络流量。所以，网络吞吐量定义为剩余带宽是有实际意义的。

## 1.5 网络带宽容量
与网络吞吐量不同，网络带宽容量指的是在网络的两个节点之间的最大可用带宽。这是由组成网络的设备的能力所决定的。
测试网络带宽容量有两个困难之处：在网络存在其它网络流量的时候，如何得知网络的最大可用带宽；在测试过程中，如何对现有的网络流量不造成影响。网络测试工具一般采用 packet pairs 和 packet trains 技术来克服这样的困难。

# 2. 性能评测
Linux环境下网络性能测试: http://www.samirchen.com/linux-network-performance-test/

http://blog.itpub.net/22664653/viewspace-714569/

Actually there are several differences:

1. IPERF is a well-written modern CLI tool, very simple to use. NETPERF looks like a museum exponate. The simplest tutorial for NETPERF I've found on the web is as easy as learning the Klingon's Kumburan dialect.

2. NETPERF reported invalid bandwidth on some machines. And those machines very just laptops connected over a simple switch.

3. NETSERVER (part of NETPERF) often reports useless machine address, so it would be better to just write nothing than misleading info.

In short, use IPERF.

## 2.1 netperf
https://www.ibm.com/developerworks/cn/linux/l-netperf/

Netperf是一种网络性能的测量工具，主要针对基于TCP或UDP的传输。Netperf根据应用的不同，可以进行不同模式的网络性能测试，即批量数据传输（bulk data transfer）模式和请求/应答（request/reponse）模式。Netperf测试结果所反映的是一个系统能够以多快的速度向另外一个系统发送数据，以及另外一个系统能够以多块的速度接收数据。

Netperf工具以client/server方式工作。server端是netserver，用来侦听来自client端的连接，client端是netperf，用来向server发起网络测试。在client与server之间，首先建立一个控制连接，传递有关测试配置的信息，以及测试的结果；在控制连接建立并传递了测试配置信息以后，client与server之间会再建立一个测试连接，用来来回传递着特殊的流量模式，以测试网络的性能。

### 2.1.1 TCP网络性能
由于TCP协议能够提供端到端的可靠传输，因此被大量的网络应用程序使用。但是，可靠性的建立是要付出代价的。TCP协议保证可靠性的措施，如建立并维护连接、控制数据有序的传递等都会消耗一定的网络带宽。
Netperf可以模拟三种不同的TCP流量模式：

- 单个TCP连接，批量（bulk）传输大量数据: TCP_STREAM
- 单个TCP连接，client请求/server应答的交易（transaction）方式: TCP_RR
- 多个TCP连接，每个连接中一对请求/应答的交易方式: TCP_CRR

### 2.1.2 UDP网络性能
UDP没有建立连接的负担，但是UDP不能保证传输的可靠性，所以使用UDP的应用程序需要自行跟踪每个发出的分组，并重发丢失的分组。
Netperf可以模拟两种UDP的流量模式：

- 从client到server的单向批量传输: UDP_STREAM
- 请求/应答的交易方式: UDP_RR

由于UDP传输的不可靠性，在使用netperf时要确保发送的缓冲区大小不大于接收缓冲区大小，否则数据会丢失，netperf将给出错误的结果。因此，对于接收到分组的统计不一定准确，需要结合发送分组的统计综合得出结论。

## 2.3 下载和安装
https://fossies.org/linux/misc/
https://www.netperf.org

**Server:**
netserver

**Client:**
netperf -t TCP_STREAM -H 192.168.0.221 -l 10


[root@hhb-xen netperf-2.7.0]# netperf -t UDP_STREAM -H 10.239.13.122 -l 10
MIGRATED UDP STREAM TEST from 0.0.0.0 (0.0.0.0) port 0 AF_INET to 10.239.13.122 () port 0 AF_INET
send_data: data send error: Network is unreachable (errno 101)
netperf: send_omni: send_data failed: Network is unreachable

会有问题，可以将命令该为如下：

netperf -H 10.239.13.122  -t UDP_STREAM -- -R 1 -l 10

## 2.2 iperf
https://iperf.fr/iperf-doc.php#3change

**arm-cross-compile**

./configure --host=arm-hisiv100nptl-linux
modify config.h
#define HAVE_MALLOC 1
#define HAVE_QUAD_SUPPORT 1
/* #undef malloc */


# 3. 性能优化
## 3.1 intel dpdk ##

数据包绕过内核，透传给用户层，能大大提高虚拟机的网络性能，比SR-IOV好很多倍

与此类似的还有 netmap

vmdq

SR_IOV


## 3.2 提高 Linux 上 socket 性能 ##

https://www.ibm.com/developerworks/cn/linux/l-hisock.html


## 3.3 Nagle算法 ##

改算法是以減少封包传送量來增进TCP/IP网络的效能

 if有新資料要傳送
   if訊窗大小>= MSS and可傳送的資料>= MSS
     立刻傳送完整MSS大小的segment
   else
    if管線中有尚未確認的資料
      在下一個確認（ACK）封包收到前，將資料排進緩衝區佇列
    else
      立即傳送資料  

https://en.wikipedia.org/wiki/Nagle's_algorithm


## 3.4 Linux下TCP/IP及内核参数优化 ##
Linux下TCP/IP及内核参数优化有多种方式，参数配置得当可以大大提高系统的性能，也可以根据特定场景进行专门的优化，如TIME_WAIT过高，DDOS攻击等等。
如下配置是写在sysctl.conf中，可使用sysctl -p生效，文中附带了一些默认值和中文解释（从网上收集和翻译而来），确有些辛苦，转载请保留链接，谢谢～。
相关参数仅供参考，具体数值还需要根据机器性能，应用场景等实际情况来做更细微调整。

	net.core.netdev_max_backlog = 400000
	#该参数决定了，网络设备接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目。

	net.core.optmem_max = 10000000
	#该参数指定了每个套接字所允许的最大缓冲区的大小

	net.core.rmem_default = 10000000
	#指定了接收套接字缓冲区大小的缺省值（以字节为单位）。

	net.core.rmem_max = 10000000
	#指定了接收套接字缓冲区大小的最大值（以字节为单位）。

	net.core.somaxconn = 100000
	#Linux kernel参数，表示socket监听的backlog(监听队列)上限

	net.core.wmem_default = 11059200
	#定义默认的发送窗口大小；对于更大的 BDP 来说，这个大小也应该更大。

	net.core.wmem_max = 11059200
	#定义发送窗口的最大大小；对于更大的 BDP 来说，这个大小也应该更大。

	net.ipv4.conf.all.rp_filter = 1
	net.ipv4.conf.default.rp_filter = 1
	#严谨模式 1 (推荐)
	#松散模式 0

	net.ipv4.tcp_congestion_control = bic
	#默认推荐设置是 htcp

	net.ipv4.tcp_window_scaling = 0
	#关闭tcp_window_scaling
	#启用 RFC 1323 定义的 window scaling；要支持超过 64KB 的窗口，必须启用该值。

	net.ipv4.tcp_ecn = 0
	#把TCP的直接拥塞通告(tcp_ecn)关掉

	net.ipv4.tcp_sack = 1
	#关闭tcp_sack
	#启用有选择的应答（Selective Acknowledgment），
	#这可以通过有选择地应答乱序接收到的报文来提高性能（这样可以让发送者只发送丢失的报文段）；
	#（对于广域网通信来说）这个选项应该启用，但是这会增加对 CPU 的占用。

	net.ipv4.tcp_max_tw_buckets = 10000
	#表示系统同时保持TIME_WAIT套接字的最大数量

	net.ipv4.tcp_max_syn_backlog = 8192
	#表示SYN队列长度，默认1024，改成8192，可以容纳更多等待连接的网络连接数。

	net.ipv4.tcp_syncookies = 1
	#表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；

	net.ipv4.tcp_timestamps = 1
	#开启TCP时间戳
	#以一种比重发超时更精确的方法（请参阅 RFC 1323）来启用对 RTT 的计算；为了实现更好的性能应该启用这个选项。

	net.ipv4.tcp_tw_reuse = 1
	#表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；

	net.ipv4.tcp_tw_recycle = 1
	#表示开启TCP连接中TIME-WAIT sockets的快速回收，默认为0，表示关闭。

	net.ipv4.tcp_fin_timeout = 10
	#表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。

	net.ipv4.tcp_keepalive_time = 1800
	#表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为30分钟。

	net.ipv4.tcp_keepalive_probes = 3
	#如果对方不予应答，探测包的发送次数

	net.ipv4.tcp_keepalive_intvl = 15
	#keepalive探测包的发送间隔

	net.ipv4.tcp_mem
	#确定 TCP 栈应该如何反映内存使用；每个值的单位都是内存页（通常是 4KB）。
	#第一个值是内存使用的下限。
	#第二个值是内存压力模式开始对缓冲区使用应用压力的上限。
	#第三个值是内存上限。在这个层次上可以将报文丢弃，从而减少对内存的使用。对于较大的 BDP 可以增大这些值（但是要记住，其单位是内存页，而不是字节）。

	net.ipv4.tcp_rmem
	#与 tcp_wmem 类似，不过它表示的是为自动调优所使用的接收缓冲区的值。

	net.ipv4.tcp_wmem = 30000000 30000000 30000000
	#为自动调优定义每个 socket 使用的内存。
	#第一个值是为 socket 的发送缓冲区分配的最少字节数。
	#第二个值是默认值（该值会被 wmem_default 覆盖），缓冲区在系统负载不重的情况下可以增长到这个值。
	#第三个值是发送缓冲区空间的最大字节数（该值会被 wmem_max 覆盖）。

	net.ipv4.ip_local_port_range = 1024 65000
	#表示用于向外连接的端口范围。缺省情况下很小：32768到61000，改为1024到65000。

	net.ipv4.netfilter.ip_conntrack_max=204800
	#设置系统对最大跟踪的TCP连接数的限制

	net.ipv4.tcp_slow_start_after_idle = 0
	#关闭tcp的连接传输的慢启动，即先休止一段时间，再初始化拥塞窗口。

	net.ipv4.route.gc_timeout = 100
	#路由缓存刷新频率，当一个路由失败后多长时间跳到另一个路由，默认是300。

	net.ipv4.tcp_syn_retries = 1
	#在内核放弃建立连接之前发送SYN包的数量。

	net.ipv4.icmp_echo_ignore_broadcasts = 1
	# 避免放大攻击

	net.ipv4.icmp_ignore_bogus_error_responses = 1
	# 开启恶意icmp错误消息保护

	net.inet.udp.checksum=1
	#防止不正确的udp包的攻击

	net.ipv4.conf.default.accept_source_route = 0
	#是否接受含有源路由信息的ip包。参数值为布尔值，1表示接受，0表示不接受。
	#在充当网关的linux主机上缺省值为1，在一般的linux主机上缺省值为0。
	#从安全性角度出发，建议你关闭该功能。

# 4. 网络流量监测
## 4.1 检测某个 接口的流量

	$ yum install iftop
	$ iftop -i eth0

## 4.2 检测具体 tcp/udp 端口流量

	$ yum install iptraf
	$ iptraf-ng
	LAN station monitor --> By TCP/UDP port
