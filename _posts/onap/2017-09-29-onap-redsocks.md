# Linux全局 HTTP 代理方案

看到 ArchWiki 上 GoAgent 条目的亚全局代理方案，只是设置了代理相关环境变量。我就想，为什么不实现一个真正的全局 HTTP 代理呢？
最终，答案是：Linux 太灵活了，以至于想写一个脚本来搞定很麻烦。不过方案如下，有兴趣的可以折腾折腾。
首先，需要用到的工具：dnsmasq、iptables、redsocks，以及 HTTP 代理工具。dnsmasq 是用来缓存 DNS 请求的，iptables 把 TCP 流转接到 redsocks，而 redsocks 将 TCP 流转接到代理上。

最小 dnsmasq 配置如下：

	1 listen-address=127.0.0.1
	2 cache-size=500
	3 server=127.0.0.1#5353
	4 bogus-nxdomain=127.0.0.1
 
这里使用了本地的 dnscrypt 服务（假设其在 5353 端口上提供服务）。也可以使用国外服务器，只是需要更细致的配置来迫使其走 TCP。

iptables 命令如下：

	1  # 创建一个叫 REDSOCKS 的链，查看和删除的时候方便
	2  iptables -t nat -N REDSOCKS
	3  # 所有输出的数据都使用此链
	4  iptables -t nat -A OUTPUT -j REDSOCKS
	5
	6  # 代理自己不要再被重定向，按自己的需求调整/添加。一定不要弄错，否则会造成死循环的
	7  iptables -t nat -I REDSOCKS -m owner --uid-owner redsocks -j RETURN
	8  iptables -t nat -I REDSOCKS -m owner --uid-owner goagent -j RETURN
	9  iptables -t nat -I REDSOCKS -m owner --uid-owner dnscrypt -j RETURN
	10
	11 # 局域网不要代理
	12 iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
	13 iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
	14 iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
	15 iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
	16 iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
	17 iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
	18 iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
	19
	20 # HTTP 和 HTTPS 转到 redsocks
	21 iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to-ports $HTTP_PORT
	22 iptables -t nat -A REDSOCKS -p tcp --dport 443 -j REDIRECT --to-ports $HTTPS_PORT
	23 # 如果使用国外代理的话，走 UDP 的 DNS 请求转到 redsocks，redsocks 会让其使用 TCP 重试
	24 iptables -t nat -A REDSOCKS -p udp --dport 53 -j REDIRECT --to-ports $DNS_PORT
	25 # 如果走 TCP 的 DNS 请求也需要代理的话，使用下边这句。一般不需要
	26 iptables -t nat -A REDSOCKS -p tcp --dport 53 -j REDIRECT --to-ports $HTTPS_PORT
	 
redsocks 的配置：
 
	01 base {
	02   log_debug = off;
	03   log_info = off;
	04   daemon = on; 
	05   redirector = iptables;
	06 }
	07 // 处理 HTTP 请求
	08 redsocks {
	09   local_ip = 127.0.0.1;
	10   local_port = $HTTP_PORT;
	11   ip = $HTTP_PROXY_IP;
	12   port = $HTTP_PROXY_PORT;
	13   type = http-relay; 
	14 }
	15 // 处理 HTTPS 请求，需要一个支持 HTTP CONNECT 的代理服务器，或者 socks 代理服务器
	16 redsocks {
	17   local_ip = 127.0.0.1;
	18   local_port = $HTTPS_PORT;
	19   ip = $SSL_PROXY_IP;
	20   port = $SSL_PROXY_PORT;
	21  type = http-connect;  // or socks4, socks5
	22 }
	23 // 回应 UDP DNS 请求，告诉其需要使用 TCP 协议重试
	24 dnstc {
	25   local_ip = 127.0.0.1;
	26   local_port = $DNS_PORT;
	27 }
 

然后以相应的用户和配置文件启动 dnsmasq 以及 redsocks。修改/etc/resolv.conf：

	01 nameserver 127.0.0.1
 

至于分流的事情，HTTP 部分可以交给 privoxy，但是 HTTPS 部分不好办。可以再设立一个像 GoAgent 那样的中间人型 HTTPS 代理，或者更简单地，直接根据 IP 地址，国内的直接RETURN掉。

以上就是整个方案了。有些麻烦而我又不需要所以没测试。反正就是这个意思。Android 软件 GAEProxy 就是这么干的（不过它没使用 iptables 的 owner 模块，导致我不小心弄出了死循环）。另外，BSD 系统也可以使用类似的方案。
