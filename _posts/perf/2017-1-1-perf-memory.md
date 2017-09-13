## 各种性能测试比较 ##
- Stream 主要聚焦于内存带宽
- LMbench provide the memory latencies for Catch L1 and L2, and also latencies for random memory access.
- Memtest86+ 主要聚焦于内存的故障检测。

##1. STREAM##
### 1.1 STREAM 介绍 ###
STREAM 是业界广为流行的综合性内存带宽实际性能 测量 工具之一。随着处理器处理核心数量的增多，内存带宽对于提升整个系统性能越发重要，如果某个系统不能够足够迅速地将内存中的数据传输到处理器当中，若干处理核心就会处于等待数据的闲置状态，而这其中所产生的闲置时间不仅会降低系统的效率还会抵消多核心和高主频所带来的性能提升因素。 STREAM 具有良好的空间局部性，是对 TLB 友好、Cache友好的一款测试。STREAM支持Copy 、Scale 、 Add、 Triad四种操作。

	http://www.cs.virginia.edu/stream/stream2
	tar -xvf stream
	cd stream &&make
	numactl -m 0 ./stream_c.exe


### 1.2 下载地址 ###
http://www.cs.virginia.edu/stream/FTP/Code/

### 1.3 Ref: ###
http://blog.csdn.net/maray/article/details/6230912

## 2.LMbench
### 2.1 LMbench介绍 ###
LMbench 是一个使用 GPL 许可证发布的的免费和开源的自由软件。主要关注两个方面：带宽(bandwidth)和延迟(latency)。它还包含了很多简单的基准测试，覆盖了文档读写、内存操作、管道、系统调用、上下文切换、进程创建和销毁、网络等多方面的性能测试。由于是开源的，我们可以对其进行修改。

**Bandwidth benchmarks**

- Cached file read
- Memory copy (bcopy)
- Memory read
- Memory write
- Pipe
- TCP

**Latency benchmarks**

Context switching.
Networking: connection establishment, pipe, TCP, UDP, and RPC hot potato
File system creates and deletes.
Process creation.
Signal handling
System call overhead
Memory read latency

**Miscellanious**

Processor clock rate calculation

### 2.2 官网 ###
http://www.bitmover.com/lmbench/

### 2.3 实际操作 ###
**下载**
https://sourceforge.net/projects/lmbench/  

**编译**
make

**执行默认测试**
make results

**查看测试结果**  
LMbench 根据配置文档执行完所需要的测试项之后，在results 目录下根据系统类型、系统名和操作系统类型等生成一个子目录，测试结果文档
按照“主机名+序列”的命令方式存放于该目录下，运行下面命令可以查看测试结果报告及其说明

	make see

你也可以将两次测试结果放在一个地方，然后执行上面的命令可以查看比较的结果。

## 3. ps_mem
ps_mem 是一个可以帮助我们精准获取 Linux 中各个程序核心内存使用情况的简单 python 脚本。这个工具和其它的区别在于其精确显示核心内存使用情况。

### 3.1 install

**redhat:**

	yum install ps_mem

**source install**

	git clone https://github.com/pixelb/ps_mem.git && cd ps_mem
	python ps_mem.py

### 3.2 use

	$ ps_mem
	$ ps_mem --help
	ps_mem.py - Show process memory usage

	-h                                 Show this help
	-w <N>                             Measure and show process memory every N seconds
	-p <pid>[,pid2,...pidN]            Only show memory usage PIDs in the specified list
	-s, --show-cmdline                 Show complete program path with options


## 3. Other benchmark
### 3.1 kernel build
内核编译是一个比较综合的性能评测工具，它广为 Linux 开发者和开源的 VMM 开发者采用。这种方法即对处理器敏感也对内存和硬盘读写敏感。因此，在实践中，内核编译既被用来做内存虚拟化的性能评测工具，也被用作硬盘虚拟化的性能评测工具。

### 3.2 sysbench
perf cpu 这篇文章中已经提了，这里不再叙述。

## 4. free

	[root@vt-nfs kvm_blog]# free -m
	              total        used        free      shared  buff/cache   available
	Mem:          15886        1383         174         599       14328       13512
	Swap:          8191         694        7497

第一行的信息（我们可以认为从操作系统层面看待）

total：总物理内存大小

used：已经分配的大小

free：没有被分配的大小

shared：共享内存的大小，主要用于IPC通信

buffers：用于块设备的缓冲

cached：用于文件内容缓冲，也就是缓存

"缓存"就是在内存中划分一块区域，作为进程和硬盘之间的缓冲区，进程将数据写入缓存中，当那些数据需要读取的时候，就直接去"高速路"缓存中读取，而不会去"土路"硬盘中读取，这样大大的加快性能

这里buffer实际上是存储了我们数据的元数据(包括目录名字，文件大小，文件存储块，修改时间，权限等)，而cache则存放了我们最近读取过的文件。

第三行信息（我们可以认为从应用程序层面看待）

这里的-/+ buffers/cache分别为 -buffers/cache  和  +buffers/cache  两部分

-buffers/cache = used(第一行)-buffers-cached   实际上是当前程序上"真实使用"的"物理内存"

+buffers/cache = buffers+cached      意思就是暂时"借给"系统作为"缓冲区"使用的内存大小

used=(+buffers/cached)+(-buffers/cached)

所以从应用程序层面看,可用内存=free memory+buffers+cached

详细信息我们可以通过下面这种方式查看.

  ~ cat /proc/meminfo 

MemTotal:        1020128 kB

MemFree:          670772 kB

Buffers:           97780 kB

Cached:           100980 kB

SwapCached:            0 kB

Active:           164988 kB

Inactive:         117296 kB

Active(anon):      83536 kB

Inactive(anon):      160 kB

Active(file):      81452 kB

Inactive(file):   117136 kB

Unevictable:           0 kB

Mlocked:               0 kB

SwapTotal:             0 kB

SwapFree:              0 kB

Dirty:                92 kB

Writeback:             0 kB

AnonPages:         83504 kB

Mapped:            17500 kB

Shmem:               172 kB

Slab:              46696 kB

SReclaimable:      28652 kB

SUnreclaim:        18044 kB

KernelStack:        1744 kB

PageTables:         2636 kB

NFS_Unstable:          0 kB

Bounce:                0 kB

WritebackTmp:          0 kB

CommitLimit:      510064 kB

Committed_AS:     343800 kB

VmallocTotal:   34359738367 kB

VmallocUsed:        7112 kB

VmallocChunk:   34359727304 kB

HardwareCorrupted:     0 kB

AnonHugePages:     36864 kB

HugePages_Total:       0

HugePages_Free:        0

HugePages_Rsvd:        0

HugePages_Surp:        0

Hugepagesize:       2048 kB

DirectMap4k:        8184 kB

DirectMap2M:     1040384 kB
