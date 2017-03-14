## 与磁盘IO子系统有关的 ##

	/proc/sys/vm/dirty_ratio

这个参数控制文件系统的文件系统写缓冲区的大小，单位是百分比，表示系统内存的百分比，表示当写缓冲使用到系统内存多少的时候，开始向磁盘写出数据。增大之会使用更多系统内存用于磁盘写缓冲，也可以极大提高系统的写性能。但是，当你需要持续、恒定的写入场合时，应该降低其数值，一般启动上缺省是10。下面是增大的方法：

  	echo '40' > /proc/sys/vm/dirty_ratio

/proc/sys/vm/dirty_background_ratio
这个参数控制文件系统的pdflush进程，在何时刷新磁盘。单位是百分比，表示系统内存的百分比，意思是当写缓冲使用到系统内存多少的时候，pdflush开始向磁盘写出数据。增大之会使用更多系统内存用于磁盘写缓冲，也可以极大提高系统的写性能。但是，当你需要持续、恒定的写入场合时，应该降低其数值，一般启动上缺省是5。下面是增大的方法：

  	echo '20' > /proc/sys/vm/dirty_background_ratio

/proc/sys/vm/dirty_writeback_centisecs
这个参数控制内核的脏数据刷新进程pdflush的运行间隔。单位是 1/100 秒。缺省数值是500，也就是 5秒。如果你的系统是持续地写入动作，那么实际上还是降低这个数值比较好，这样可以把尖峰的写操作削平成多次写操作。设置方法如下：

  	echo "200" > /proc/sys/vm/dirty_writeback_centisecs

如果你的系统是短期地尖峰式的写操作，并且写入数据不大（几十M/次）且内存有比较多富裕，那么应该增大此数值：

	echo "1000" > /proc/sys/vm/dirty_writeback_centisecs

/proc/sys/vm/dirty_expire_centisecs
这个参数声明Linux内核写缓冲区里面的数据多“旧”了之后，pdflush进程就开始考虑写到磁盘中去。单位是1/100秒。缺省是 30000，也就是 30秒的数据就算旧了，将会刷新磁盘。对于特别重载的写操作来说，这个值适当缩小也是好的，但也不能缩小太多，因为缩小太多也会导致IO提高太快。建议设置为1500，也就是15秒算旧。

	echo "1500" > /proc/sys/vm/dirty_expire_centisecs

当然，如果你的系统内存比较大，并且写入模式是间歇式的，并且每次写入的数据不大（比如几十M），那么这个值还是大些的好。

## 与网络IO子系统有关的 ##

	/proc/sys/net/ipv4/tcp_retrans_collapse

这个参数控制TCP双方Window协商出现错误的时候的一些重传的行为。但是在老的2.6的核（<2.6.18）里头，这个重传会导致kernel oops，kernel panic，所以，如果出现有tcp_retrans_*样子的kernel panic，可以把这个参数给设置成0：

  	echo '0' > /proc/sys/net/ipv4/tcp_retrans_collapse

提高Linux应对短连接的负载能力
在存在大量短连接的情况下，Linux的TCP栈一般都会生成大量的 TIME_WAIT状态的socket。你可以用下面的命令看到：

  	netstat -ant| grep -i time_wait

有时候，这个数目是惊人的：

  	netstat -ant|grep -i time_wait |wc -l

可能会超过三四万。这个时候，