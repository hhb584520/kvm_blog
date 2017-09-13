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

# 3. nc命令是netcat命令的简称，用来设置路由器 #

## 3.1 语法 ##

    nc/netcat(选项)(参数)
    选项
    
    -g<网关>：设置路由器跃程通信网关，最多设置8个；
    -G<指向器数目>：设置来源路由指向器，其数值为4的倍数；
    -h：在线帮助；
    -i<延迟秒数>：设置时间间隔，以便传送信息及扫描通信端口；
    -l：使用监听模式，监控传入的资料；
    -n：直接使用ip地址，而不通过域名服务器；
    -o<输出文件>：指定文件名称，把往来传输的数据以16进制字码倾倒成该文件保存；
    -p<通信端口>：设置本地主机使用的通信端口；
    -r：指定源端口和目的端口都进行随机的选择；
    -s<来源位址>：设置本地主机送出数据包的IP地址；
    -u：使用UDP传输协议；
    -v：显示指令执行过程；
    -w<超时秒数>：设置等待连线的时间；
    -z：使用0输入/输出模式，只在扫描通信端口时使用。
    
	参数
    主机：指定主机的IP地址或主机名称；
    端口号：可以是单个整数或者是一个范围。

## 3.2 实例 ##

### 3.2.1 远程拷贝文件

从server1拷贝文件到server2上。需要先在server2上，用nc激活监听。

	server2上运行：
    [root@localhost2 tmp]# nc -lp 1234 > install.log

    server1上运行：
    [root@localhost1 ~]# ll install.log
    -rw-r–r–   1 root root 39693 12月 20   2007 install.log
    
    [root@localhost1 ~]# nc -w 1 192.168.228.222 1234 < install.log
    克隆硬盘或分区

操作与上面的拷贝是雷同的，只需要由dd获得硬盘或分区的数据，然后传输即可。克隆硬盘或分区的操作，不应在已经mount的的系统上进行。所以，需要使用安装光盘引导后，进入拯救模式（或使用Knoppix工 具光盘）启动系统后，在server2上进行类似的监听动作：

    nc -l -p 1234 | dd of=/dev/sda

server1上执行传输，即可完成从server1克隆sda硬盘到server2的任务：

    dd if=/dev/sda | nc 192.168.228.222 1234

完成上述工作的前提，是需要落实光盘的拯救模式支持服务器上的网卡，并正确配置IP。

### 3.2.2 端口扫描

    nc -v -w 1 192.168.228.222 -z 1-1000
    localhost2 [192.168.228.222] 22 (ssh) open

保存Web页面

    while true; do
    	nc -l -p 80 -q 1 < somepage.html;
    done

### 3.2.3 聊天

nc还可以作为简单的字符下聊天工具使用，同样的，server2上需要启动监听：

[root@localhost2 tmp]# nc -lp 1234
server1上传输：

[root@localhost1 ~]# nc 192.168.228.222 1234
这样，双方就可以相互交流了。使用Ctrl+D正常退出。

### 3.2.4 传输目录

从server1拷贝nginx-0.6.34目录内容到server2上。需要先在server2上，用nc激活监听，server2上运行：

[root@localhost2 tmp]# nc -l 1234 | tar xzvf -
server1上运行：

[root@localhost1 ~]# ll -d nginx-0.6.34
drwxr-xr-x 8 1000 1000 4096 12-23 17:25 nginx-0.6.34

[root@localhost1 ~]# tar czvf – nginx-0.6.34 | nc 192.168.228.222 1234


# 4. iptables #
## 4.1 介绍

![](/kvm_blog/img/iptables-snat.png)

![](/kvm_blog/img/iptables_traverse.jpg)

iptables 的表和链： 

现在，让我们看看当一个数据包到达时它是怎么依次穿过各个链和表的。基本步骤如下：

	1. 数据包到达网络接口，比如 eth0。
	2. 进入 raw 表的 PREROUTING 链，这个链的作用是赶在连接跟踪之前处理数据包。
	3. 如果进行了连接跟踪，在此处理。
	4. 进入 mangle 表的 PREROUTING 链，在此可以修改数据包，比如 TOS 等。
	5. 进入 nat 表的 PREROUTING 链，可以在此做DNAT，但不要做过滤。
	6. 决定路由，看是交给本地主机还是转发给其它主机。
	到了这里我们就得分两种不同的情况进行讨论了，一种情况就是数据包要转发给其它主机，这时候它会依次经过：
	7. 进入 mangle 表的 FORWARD 链，这里也比较特殊，这是在第一次路由决定之后，在进行最后的路由决定之前， 我们仍然可以对数据包进行某些修改。
	8. 进入 filter 表的 FORWARD 链，在这里我们可以对所有转发的数据包进行过滤。需要注意的是：经过这里的数据包是转发的，方向是双向的。
	9. 进入 mangle 表的 POSTROUTING 链，到这里已经做完了所有的路由决定，但数据包仍然在本地主机，我们还可以进行某些修改。
	10. 进入 nat 表的 POSTROUTING 链，在这里一般都是用来做 SNAT ，不要在这里进行过滤。
	11. 进入出去的网络接口。完毕。
	另一种情况是，数据包就是发给本地主机的，那么它会依次穿过：
	7. 进入 mangle 表的 INPUT 链，这里是在路由之后，交由本地主机之前，我们也可以进行一些相应的修改。
	8. 进入 filter 表的 INPUT 链，在这里我们可以对流入的所有数据包进行过滤，无论它来自哪个网络接口。
	9. 交给本地主机的应用程序进行处理。
	10. 处理完毕后进行路由决定，看该往那里发出。
	11. 进入 raw 表的 OUTPUT 链，这里是在连接跟踪处理本地的数据包之前。
	12. 连接跟踪对本地的数据包进行处理。
	13. 进入 mangle 表的 OUTPUT 链，在这里我们可以修改数据包，但不要做过滤。
	14. 进入 nat 表的 OUTPUT 链，可以对防火墙自己发出的数据做 NAT 。
	15. 再次进行路由决定。
	16. 进入 filter 表的 OUTPUT 链，可以对本地出去的数据包进行过滤。
	17. 进入 mangle 表的 POSTROUTING 链，同上一种情况的第9步。注意，这里不光对经过防火墙的数据包进行处理，还对防火墙自己产生的数据包进行处理。
	18. 进入 nat 表的 POSTROUTING 链，同上一种情况的第10步。
	19. 进入出去的网络接口。完毕。
 

## 4.2 iptables 的基本用法

	iptables [-t table] -[AD] chain rule-specification [options]
	iptables [-t table] -I chain [rulenum] rule-specification [options]
	iptables [-t table] -R chain rulenum rule-specification [options]
	iptables [-t table] -D chain rulenum [options]
	iptables [-t table] -[LFZ] [chain] [options]
	iptables [-t table] -N chain
	iptables [-t table] -X [chain]
	iptables [-t table] -P chain target [options]
	iptables [-t table] -E old-chain-name new-chain-name

下面我们来详细看一下各个选项的作用：
-t, --table table
对指定的表 table 进行操作， table 必须是 raw， nat，filter，mangle 中的一个。如果不指定此选项，默认的是 filter 表。
-L, --list [chain]
列出链 chain 上面的所有规则，如果没有指定链，列出表上所有链的所有规则。例子：

	# iptables -L INPUT
-F, --flush [chain]
清空指定链 chain 上面的所有规则。如果没有指定链，清空该表上所有链的所有规则。例子：

	# iptables -F
-A, --append chain rule-specification
在指定链 chain 的末尾插入指定的规则，也就是说，这条规则会被放到最后，最后才会被执行。规则是由后面的匹配来指定。例子：

	# iptables -A INPUT -s 192.168.20.13 -d 192.168.1.1 -p TCP –dport 22 -j ACCEPT
-D, --delete chain rule-specification
-D, --delete chain rulenum
在指定的链 chain 中删除一个或多个指定规则。如上所示，它有两种格式的用法。例子：

	# iptables -D INPUT --dport 80 -j DROP
	# iptables -D INPUT 1
-I, --insert chain [rulenum] rule-specification
在链 chain 中的指定位置插入一条或多条规则。如果指定的规则号是1，则在链的头部插入。这也是默认的情况，如果没有指定规则号。 例子：

	# iptables -I INPUT 1 --dport 80 -j ACCEPT
-R, --replace chain rulenum rule-specification
用新规则替换指定链 chain 上面的指定规则，规则号从1开始。例子：

	# iptables -R INPUT 1 -s 192.168.1.41 -j DROP
-N, --new-chain chain
用指定的名字创建一个新的链。例子：

	# iptables -N mychain
-X, --delete-chain [chain]
删除指定的链，这个链必须没有被其它任何规则引用，而且这条上必须没有任何规则。如果没有指定链名，则会删除该表中所有非内置的链。例子：

	# iptables -X mychain
-E, --rename-chain old-chain new-chain
用指定的新名字去重命名指定的链。这并不会对链内部照成任何影响。例子：

	# iptables -E mychain yourchain
-P, --policy chain target
为指定的链 chain 设置策略 target。注意，只有内置的链才允许有策略，用户自定义的是不允许的。例子：
	
	# iptables -P INPUT DROP
-Z, --zero [chain]
把指定链，或者表中的所有链上的所有计数器清零。例子：
	
	# iptables -Z INPUT
上面列出的都是对链或者表的操作，下面我们再来看一下对规则进行操作的基本选项：
-p, --protocol [!] proto
指定使用的协议为 proto ，其中 proto 必须为 tcp udp icmp 或者 all ，或者表示某个协议的数字。 如果 proto 前面有“!”，表示对取反。例子：

	# iptables -A INPUT -p tcp [...]
-j, --jump target
指定目标，即满足某条件时该执行什么样的动作。target 可以是内置的目标，比如 ACCEPT，也可以是用户自定义的链。例子：

	# iptables -A INPUT -p tcp -j ACCEPT
-s, --source [!] address[/mask]
把指定的一个／一组地址作为源地址，按此规则进行过滤。当后面没有 mask 时，address 是一个地址，比如：192.168.1.1；当 mask 指定时，可以表示一组范围内的地址，比如：192.168.1.0/255.255.255.0。一个完整的例子：

	# iptables -A INPUT -s 192.168.1.1/24 -p tcp -j DROP
-d, --destination [!] address[/mask]
地址格式同上，但这里是指定地址为目的地址，按此进行过滤。例如：

	# iptables -A INPUT -d 192.168.1.254 -p tcp -j ACCEPT
-i, --in-interface [!] name
指定数据包的来自来自网络接口，比如最常见的 eth0 。注意：它只对 INPUT，FORWARD，PREROUTING 这三个链起作用。如果没有指定此选项， 说明可以来自任何一个网络接口。同前面类似，"!" 表示取反。例子：
	
	# iptables -A INPUT -i eth0
-o, --out-interface [!] name
指定数据包出去的网络接口。只对 OUTPUT，FORWARD，POSTROUTING 三个链起作用。例如：
	
	# iptables -A FORWARD -o eth0
--source-port,--sport port[:port]
在 tcp/udp/sctp 中，指定源端口。冒号分隔的两个 port 表示指定一段范围内的所有端口，大的小的哪个在前都可以，比如： “1:100” 表示从1号端口到100号（包含边界），而 “:100” 表示从 0 到 100，“100:”表示从100到65535。一个完整的例子如下：

	# iptables -A INPUT -p tcp --sport 22 -j REJECT
--destination-port,--dport port[,port]
指定目的端口，用法和上面类似，但如果要指定一组端口，格式可能会因协议不同而不同，注意浏览 iptables 的手册页。例如：

	# iptables -A INPUT -p tcp --dport 22 -j ACCEPT

另外，一些协议还有自己专有的选项，想了解更多请查看 iptables 的手册页。

到这里，主要的选项已经介绍个差不多了，另一个问题随之也产生了， 如何保存我们的 iptables 的规则呢？一个很容易想到的办法是把这些 iptables 命令做成脚本，然后执行脚本即可。不错，这的确 可以完成我们的任务，但这样效率不高，因为每执行一条 iptables 命令都要重新访问内核，如果规则很多很多，这会浪费比较多的时间。 取而代之的方法是，使用 iptables-save 和 iptables-restore 这两条命令，它们访问一次内核就可以保存或读取所有规则。 这两条命令很简单，我们下面就来看一下。 

iptables-save 命令的格式很简单，如下：

    iptables-save [-c] [-t table]

iptables-save 会把规则以某种格式打印到标准输出，通过重定向我们可以把它保存到某个文件。其中， -c 告诉它也要保存计数器， 如果我们想重启 iptables 但又不想丢弃当前的计数，我们可以加此选项。 -t 告诉它只保存指定的表，如果没有此选项则会保存所有的表。 

iptables-save 的输出格式其实也很简单，一个示例如下：

	# Generated by iptables-save v1.2.6a on Wed Apr 24 10:19:55 2002
	*filter
	:INPUT DROP [1:229]
	:FORWARD DROP [0:0]
	:OUTPUT DROP [0:0]
	-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
	-A FORWARD -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	-A FORWARD -i eth1 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
	-A OUTPUT -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
	COMMIT
	# Completed on Wed Apr 24 10:19:55 2002
	# Generated by iptables-save v1.2.6a on Wed Apr 24 10:19:55 2002
	*mangle
	:PREROUTING ACCEPT [658:32445]
	:INPUT ACCEPT [658:32445]
	:FORWARD ACCEPT [0:0]
	:OUTPUT ACCEPT [891:68234]
	:POSTROUTING ACCEPT [891:68234]
	COMMIT
	# Completed on Wed Apr 24 10:19:55 2002
	# Generated by iptables-save v1.2.6a on Wed Apr 24 10:19:55 2002
	*nat
	:PREROUTING ACCEPT [1:229]
	:POSTROUTING ACCEPT [3:450]
	:OUTPUT ACCEPT [3:450]
	-A POSTROUTING -o eth0 -j SNAT --to-source 195.233.192.1
	COMMIT
	# Completed on Wed Apr 24 10:19:55 2002

在上面，以#开头的都是注释，里面包含了一些时间信息等。表名在 * 之后，比如： *nat。以冒号开头的行格式如下：
:<链名> <策略> [<包计数器>:<字节计数器>]
其余的行，很明显，表示传递给 iptables 的选项。 

iptables-restore 命令同样简单，它从标准输入读入上述格式的数据并恢复规则。

    iptables-restore [-c] [-n]

其中 -c 表示恢复计数器；-n 表示不要覆盖先前的规则，如不指定， iptables-restore 会先把前面的规则全部清掉。 所以这两条命令常见的用法是：

	# iptables-save -c > /etc/iptables-save
	# iptables-restore -c < /etc/iptables-save

## 4.3 iptables 高级功能
### 4.3.1 字符串匹配
iptables还有一个很强大的功能就是可以通过字符串匹配进行包过滤，这在某种程度上实现了应用层数据过滤的功能。 我们需要用到iptables的string模块。 关于string模块的具体用法，可以查看其帮助信息：

	# iptables -m string --help

比如，我们要过滤所有TCP连接中的字符串“test”，一旦出现它我们就终止这个连接，我们可以这么做：

	# iptables -A INPUT -p tcp -m string --algo kmp --string "test" -j REJECT --reject-with tcp-reset
	# iptables -L
		Chain INPUT (policy ACCEPT)
		target     prot opt source               destination        
		REJECT     tcp  --  anywhere             anywhere            STRING match "test" ALGO name kmp TO 65535 reject-with tcp-reset
		 
		Chain FORWARD (policy ACCEPT)
		target     prot opt source               destination        
		 
		Chain OUTPUT (policy ACCEPT)
		target     prot opt source               destination  
      
这时，如果我们再去用telnet连接，一旦发出包含有“test”字样的数据，连接马上就会中断。

	$ nc  -l 5678
 
	$ telnet localhost 5678
	Trying 127.0.0.1...
	Connected to localhost.
	Escape character is '^]'.
	test
	Connection closed by foreign host.

字符串匹配过滤一个比较有实用的用法是：

	# iptables -I INPUT -j DROP -p tcp -s 0.0.0.0/0 -m string --algo kmp --string "cmd.exe"

它可以用来阻止Windows蠕虫的攻击。 

### 4.3.2 应用层过滤

传统的 iptables 是不能直接对应用层进行过滤的，要想使用 iptables 进行应用层过滤，必须安装 l7-filter 。 到l7-filter的官方网站下载其最新的补丁包。 解压后可以看到所有补丁，其中补丁 'iptables-1.3-for-kernel-pre2.6.20-layer7-2.19.patch' 是给 iptables 1.3.X 的，补丁 'kernel-2.6.18-2.6.19-layer7-2.9.patch' 是为 2.6.19.X 内核准备的。我们以这种环境为例看一下如何安装 l7-filter。

	$ cd linux-2.6.19
	$ patch -p1 < ../kernel-2.6.18-2.6.19-layer7-2.9.patch
然后开始编译内核，注意，配置内核时记得要设置 'CONFIG_IP_NF_MATCH_LAYER7=m'，其它步骤照常。 

编译并安装好内核之后，我们接着安装 iptables 的补丁，我们需要： 

	$ cd iptables-1.3.8
	$ patch -p1 < ../iptables-1.3-for-kernel-pre2.6.20-layer7-2.19.patch
	$ chmod +x extensions/.layer7-test
	$ export KERNEL_DIR=/usr/src/linux-2.6.19
接着我们就可以正常编译 iptables 了。编译并安装完之后，我们就可以使用 l7-filter 了。使用前我们还需要到 http://l7-filter.sourceforge.net/protocols 下载对应的 protocol 文件，保存到 /etc/l7-protocols 目录中。比如我要过滤 ssh ，我就可以只下载 ssh.pat （要安装全部 protocol 文件可以在官方网站下载 l7-protocols-2008-04-23.tar.gz 安装包）。 

这一步完成后我们终于可以使用它进行应用层的过滤了，比如，我想过滤掉 ssh 连接，我可以：

	# iptables -m layer7 -t mangle -I PREROUTING --l7proto ssh -j DROP
l7-filter 还支持其它很多协议，包括 BitTorrent，Xunlei 等等。 

### 4.3.3 动态过滤

传统的防火墙只能进行静态过滤，而 iptables 除了这个基本的功能之外还可以进行动态过滤，即可以对连接状态进行跟踪，通常称为 conntrack 。 但这不意味着它只能对 TCP 这样的面向连接的协议有效，它还可以对 UDP， ICMP 这种无连接的协议进行跟踪，我们下面马上就会看到。 

iptables 中的连接跟踪是通过 state 模块来实现的，是在PREROUTING 链中完成的，除了本地主机产生的数据包，它们是在 OUTPUT 链中完成。 它把“连接”划分为四种状态：NEW， ESTABLISHED， RELATED 和 INVALID。连接跟踪当前的所有连接状态可以通过 /proc/net/nf_conntrack 来查看（注意，在一些稍微旧的 Linux 系统上是 /proc/net/ip_conntrack）。 

当 conntrack 第一次看到相关的数据包时，就会把状态标记为 NEW ，比如 TCP 协议中收到第一个 SYN 数据包。当连接的双方都有数据包收发并且还将继续匹配到这些数据包时，连接状态就会变为 ESTABLISHED 。而 RELATED 状态是指一个新的连接，但这个连接和某个已知的连接有关系，比如 FTP 协议中的数据传输连接。INVALID 状态是说数据包和已知的任何连接都不匹配。 

对于 TCP 协议，这很容易理解，因为它本身就是面向连接的，唯一需要额外指出的是这里的 ESTABLISHED 状态并不完全等于 TCP 中的 ESTABLISHED 。 使用示例：

	# iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT

而对于 UDP 协议可能稍微有些困难，但如果对照上面的解释应该可以理解。对于 conntrack 来说，它其实和 TCP 没太大区别。例子：

	# iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT

最难理解的应该是 ICMP ，它比 UDP 离“面向连接”更远。:-) 我们需要记住的是，当遇到 ICMP Request 时为 NEW，遇到对应的 ICMP Reply 时会变为 ESTABLISHED 。其中 request 及其对应的 reply 可以是：1) Echo request/reply ；2) Timestamp request/reply ； 3) Information request/reply ；4) Address mask request/reply 。 其它类型的 ICMP 包都是非 request/reply ，会被标记为 RELATED 。例子：

	# iptables -A OUTPUT  -p icmp -m state --state ESTABLISHED,RELATED  -j ACCEPT

iptable 使用实例：
默认策略：

    iptables -P INPUT ACCEPT
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

接受所有ssh连接：

    iptables -A INPUT -p tcp -m tcp -s 0/0 --dport 22 -j ACCEPT

管理FTP连接：

    iptables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
    iptables -A INPUT -p tcp -s 127.0.0.1/8 -d 0/0 --destination-port 20 --syn -j ACCEPT
    iptables -A INPUT -p tcp -s 127.0.0.1/8 -d 0/0 --destination-port 21 --syn -j ACCEPT

监视SNMP:

    iptables -A INPUT -p udp -m udp --dport 161 -j ACCEPT
    iptables -A INPUT -p udp -m udp --sport 1023:2999 -j ACCEPT

管理POP电子邮件：

    iptables -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT --syn

HTTPS服务：

    iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT --syn

SMTP连接：
    iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT --syn

管理HTTP：

    iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT --syn

管理MySQL数据库：

    iptables -A INPUT -p tcp -m tcp --dport 3306 -j ACCEPT --syn
    iptables -A INPUT -p udp -m udp --dport 3306 -j ACCEPT

IMAP邮件服务：

    iptables -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT --syn

管理DNS服务：

    iptables -A INPUT -p tcp -m tcp --dport 53 -j ACCEPT --syn
    iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
    iptables -A INPUT -p udp -m udp -s 0/0 -d 0/0 --sport 53 -j ACCEPT

管理本地主机连接：

    iptables -A INPUT -i lo -j ACCEPT -m tcp

丢弃所有其它的新请求：

    iptables -A INPUT -p tcp -m tcp -j REJECT --syn
    iptables -A INPUT -p udp -m udp -j REJECT

防止SYN洪水攻击：

    iptables -A INPUT -p tcp --syn -m limit --limit 5/second -j ACCEPT

屏蔽恶意主机（比如，192.168.0.8）：

    iptables -A INPUT -p tcp -m tcp -s 192.168.0.8 -j DROP

检查防火墙日志：

    iptables -A INPUT -j LOG --log-level alert
    iptables -A INPUT -j LOG --log-prefix "Dropped: "

做 NAT：

    iptables -A POSTROUTING -t nat -o eth0 -s 192.168.1.0/24 -d 0/0 -j MASQUERADE
    iptables -A FORWARD -t filter -o eth0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -t filter -i eth0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# 5. 网络配置
## 5.1 for ubuntu
	auto lo
	iface lo inet loopback
	
	auto eth0
	iface eth0 inet static
	        address 115.238.105.214
	        netmask 255.255.255.248
	        network 115.238.105.208
	        broadcast 115.238.105.215
	        gateway 115.238.105.209
	        # dns-* options are implemented by the resolvconf package, if installed
	        dns-nameservers 202.101.172.25
	
	auto eth2
	iface eth2 inet manual
	
	auto br0
	iface br0 inet static
	        bridge_ports eth2
	        address 12.0.0.200
	        netmask 255.255.255.0
	        network 12.0.0.0
	        broadcast 12.0.0.255
	        gateway 12.0.0.1
	        # dns-* options are implemented by the resolvconf package, if installed
	        dns-nameservers 12.0.0.1

## 5.2 for redhat

	$ cat /etc/sysconfig/network/ifcfg-eth2
		BOOTPROTO='none'
		BROADCAST=''
		DHCLIENT_SET_DEFAULT_ROUTE='yes'
		ETHTOOL_OPTIONS=''
		IPADDR=''
		MTU=''
		NAME='Ethernet Controller 10-Gigabit X540-AT2'
		NETMASK=''
		NETWORK=''
		REMOTE_IPADDR=''
		STARTMODE='auto'
	
	$ cat /etc/sysconfig/network/ifcfg-br2
		BOOTPROTO='dhcp4'
		BRIDGE='yes'
		BRIDGE_FORWARDDELAY='0'
		BRIDGE_PORTS='eth2'
		BRIDGE_STP='off'
		BROADCAST=''
		DHCLIENT_SET_DEFAULT_ROUTE='yes'
		ETHTOOL_OPTIONS=''
		IPADDR=''
		MTU=''
		NAME=''
		NETMASK=''
		NETWORK=''
		REMOTE_IPADDR=''
		STARTMODE='auto'


# 6.route

https://www.cyberciti.biz/faq/linux-route-add/

	$ mtr -r -c 1 ip_addr

# 7. 网卡命名机制 ##
1.传统命名：以太网eth[0,1,2,...],wlan[0,1,2,...]
2.udev支持多种不同的命名方案：UDEV是系统在用户空间探测内核空间，通过sys接口所输出的硬件设备，并配置的硬件设备的一种应用程序，在centos7上UDEV支持多种不同的命名方案，无非就是支持基于固件的命名（firmware,基于主板上rom芯片）或者是通过总线拓扑（PCI总线）结构来命名。总线拓扑（PCI总线）结构命名主要是根据对应设备所在的位置来命名，slot设备上的第几个接口方式命名，这样命名的方式就是能够实现自动命名，只要接口不坏，无论是哪一块网卡插上去其名称一定是固定的。
名称组成格式：  

- en: ethernet  
- wl: wlan(无线网卡）  
- ww: wwan（广域网拨号）  

名称类型：  

- o<index>: 集成设备的设备索引号(基于主板上rom芯片)；
- s<slot>: PCI-E扩展槽的索引号
- x<MAC>: 基于MAC地址的命名；
- p<bus>s<slot>:enp2s1


# 8. firewalld

Disable FirewallD on RHEL 7
This topic describes how to stop and disable FirewallD on RHEL 7.

To stop and disable FirewallD
Check the status of the firewalld service:

	systemctl status firewalld.service

The status displays as active (running) or inactive (dead).
If the firewall is active / running, enter this command to stop it:

	systemctl stop firewalld.service

To completely disable the firewalld service, so it does not reload when you restart the host machine:

	systemctl disable firewalld.service

Verify the status of the firewalld service:

	systemctl status firewalld.service

The status should display as disabled and inactive (dead).

	firewalld.service - firewalld - dynamic firewall daemon
	  Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
	  Active: inactive (dead)

Repeat these steps for all host machines.
The firewalld service is stopped and disabled. You can now start the CLC and other host machines.


# 参考资料 #

https://wiki.archlinux.org/index.php/Iptables_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)  
http://blog.clanzx.net/2013/08/22/rp_filter.html