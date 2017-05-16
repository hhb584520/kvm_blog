# 1. 性能评测
## 1.1 SPECvirt 介绍
[zh-rhev-performance-specvirt-benchmark.pdf](/kvm_blog/files/perf/zh-rhev-performance-specvirt-benchmark-11728837.pdf)

# 2. 性能分析
主要几类系统分析工具，一种是通过软件预先设定的探针，来记录 VMM 感兴趣的事件。

## 2.1 Xen

### 2.1.1 xentrace
Xentrace 本身设计得很通用，通过在 Hypervisor 中与性能相关的关键路径上(例如客户机调度、Hypercall操作)插入探针记录点，当关键路径被执行到的时候就新产生一条记录，包含发生的时间戳及其他详细状态。分析人员可以事先根据自己感兴趣的记录类型设置过滤器，也就是说，只有通过过滤器筛选之后的记录才会被写到一个固定的环形缓冲区里面，其余的将被丢弃。该缓冲区通过一个特殊接口同时被映射到 Dom0中的 Xentrace 应用程序的进程空间，Xentrace 读出并保存缓冲区中的记录，以供事后统计分析。

例如为了统计 VM Exit 的开销，可以在处理 VM Exit 开始和结束的地方分别设置一个记录点，通过这两条记录之间的时间戳差值，可以获得尽可能准确的各种 VM Exit 发生的概率和开销

### 2.1.2 xentop
Xentop 就是基于 Xen 的资源利用率统计工具。它运行在 Dom0的应用程序空间，使用一套特权 Hypercall 接口来获得当前系统中的各个客户机对不同资源使用情况的历史数据，通过固定间隔的轮询和比较历史数据之间的变化，就可以计算出各资源的利用率。

### 2.1.3 xl dmesg

### 2.1.4 xl log


## 2.2 KVM

### 2.2.1 top

### 2.2.2 perf

### 2.2.3 kvmtrace

### 2.2.4 kvm_stat