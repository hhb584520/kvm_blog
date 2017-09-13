# 1. iptables #

![](/kvm_blog/files/kernel/iptables-snat.png)

![](/kvm_blog/files/kernel/iptables_traverse.jpg)

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
 

# 2. iptables 的基本用法： #

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

# 2. iptables 高级功能 #
## 2.1 字符串匹配 ##
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

## 2.2 应用层过滤  ##

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

## 2.3 动态过滤  ##

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

# 参考资料 #

https://wiki.archlinux.org/index.php/Iptables_(%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87)