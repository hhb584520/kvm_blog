# 1.IOPS的测试benchmark工具 #

IOPS，即I/O per second，即每秒读写（I/O）操作的次数，多用于OLTP/数据库、小文件存储等场合，衡量随机访问的性能。

IOPS的测试benchmark工具主要有Iometer, IoZone, FIO等，可以综合用于测试磁盘在不同情形下的IOPS。对于应用系统，需要首先确定数据的负载特征，然后选择合理的IOPS指标进行测量和对比分析，据此选择合适的存储介质和软件系统。


# 2.硬盘测试
## 2.1 hdparm
### 2.1.1 install

	yum install hdparm -y

### 2.1.2 usage

http://www.ha97.com/4963.html

**测试速率**

	hdparm -tT /dev/sda

**显示硬盘的相关设置**

	[root@oracle ~]# hdparm /dev/sda
	/dev/sda:
	IO_support = 0 (default 16-bit)
	readonly = 0 (off)
	readahead = 256 (on)
	geometry = 19929［柱面数］/255［磁头数］/63［扇区数］, sectors = 320173056［总扇区数］, start = 0［起始扇区数］

# 3.参考资料 #

http://elf8848.iteye.com/blog/1731274

http://elf8848.iteye.com/blog/1731301