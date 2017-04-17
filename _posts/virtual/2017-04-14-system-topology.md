
## 1.1 CPU 拓扑结构 ##

看下Intel CPU的各个部件之间的关系：
一个NUMA node包括一个或者多个Socket，以及与之相连的local memory。一个多核的Socket有多个Core。如果CPU支持HT，OS还会把这个Core看成 2个Logical Processor。


https://github.com/RRZE-HPC/likwid
http://blog.yufeng.info/archives/2422#more-2422
https://software.intel.com/zh-cn/articles/intel-64-architecture-processor-topology-enumeration

http://unicornx.github.io/2016/03/26/20160326-mem-shared-arch/


在Linux中查看计算机系统的处理器Topology
基本上是利用sys文件系统和proc文件系统，其实我觉得sys文件系统中的信息还是最最全的：

但注意不是所有的计算机系统都支持Node的概念，普通的桌面系统可能没有Node，可以忽略查看node这一层，直接进入第二层Socket。

NUMA node

方法一：安装numactl，然后运行numactl --show，如果系统报告No NUMA support available on this system.则说明当前系统不支持NUMA，否则如果支持，可以继续运行numactl --hardware查看详细信息。

方法二：查看sys文件系统，运行ls /sys/devices/system/node/，如果系统不支持NUMA则该路径不存在。

Socket

运行cat /proc/cpuinfo|grep "physical id"，puinfo里的physical id描述的就是Socket的编号。

Core

运行`cat /proc/cpuinfo | grep “core id”

Logical Processor

运行cat /proc/cpuinfo | grep "processor"

其实要想查看这些信息也可以去sysfs的/sys/devices/system/cpu

譬如如果想查看更详细的每个CPU的cache的信息，我们知道CPU cache分为L1，L2，L3, L1一般还分为独立的指令cache和数据cache。可以运行ls /sys/devices/system/cpu/cpu0/cache/，该目录下4个目录

index0:1级数据cache
index1:1级指令cache
index2:2级cache
index3:3级cache ,对应cpuinfo里的cache
以上内容主要参考了玩转CPU Topology。这篇文章还介绍了更多NUMA架构下计算机系统的测试经验和技巧，但对于我来说可能更适合服务器端工程师去了解，至少目前在嵌入式开发侧，其实了解到SMP层次就足矣，也就是说我们可以忽略跨node的情况。但这并不意味着我们不需要了解node的概念，因为在最新的Linux内核里是支持这个概念并且其内存分配子系统也是基于这些概念设计的。****


http://www.wowotech.net/pm_subsystem/cpu_topology.html