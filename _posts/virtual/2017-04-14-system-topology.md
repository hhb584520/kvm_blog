
## 1.1 CPU 拓扑结构 ##

看下Intel CPU的各个部件之间的关系：
一个NUMA node包括一个或者多个Socket，以及与之相连的local memory。一个多核的Socket有多个Core。如果CPU支持HT，OS还会把这个Core看成 2个Logical Processor。


https://github.com/RRZE-HPC/likwid
http://blog.yufeng.info/archives/2422#more-2422
https://software.intel.com/zh-cn/articles/intel-64-architecture-processor-topology-enumeration