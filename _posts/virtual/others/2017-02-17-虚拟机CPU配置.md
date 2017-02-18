# 1. CPU概念 #
CPU(s) (逻辑CPU数) = Socket(s) * Core(s) per socket  * Thread(s) per core

	# lscpu
	CPU(s):                56
	On-line CPU(s) list:   0-55
	Thread(s) per core:    2
	Core(s) per socket:    14
	Socket(s):             2


【逻辑CPU数】CPU(s):                56
      cat /proc/cpuinfo | grep "processor" | wc -l

【每个核上的逻辑CPU个数】Thread(s) per core:    2
           
【每个物理CPU上核的个数】Core(s) per socket:    14
     cat /proc/cpuinfo | grep "core id" |  sort | uniq | wc -l
【物理CPU数】Socket(s):             2
     cat /proc/cpuinfo | grep "physical id" |  sort | uniq | wc -l

# 2. CPU过载使用 #

关于 CPU的过载使用，最不推荐的做法是让某一个客户机的 vCPU 数量超过物理系统上存在的CPU数量。比如，在拥有4个逻辑CPU的宿主机中，同时运行一个或多个客户机，其中每个客户机的 vCPU 数量多于4个。推荐的做法是对多个单CPU的客户机使用 over-commit，比如，在拥有4个逻辑CPU的宿主机中，同事运行多于4个客户机。

# 3. qemu-system-x86_64 命令参数 #
如果不设置，默认值除 maxcpus 外，其余全为 1
    
-smp n[,maxcpus=cpus][,cores=cores][,threads=threads][,sockets=sockets]

    可以使用下面命令查看
        info cpus 
        ps -efL | grep qemu   # 其中 -L可以查看线程 ID。

# 4. CPU 模型 #

- 查看当前的 QEMU 支持的所有 CPU 模型（cpu_model, 默认的模型为qemu64）
        
	qemu-system-x86_64 -cpu ?
	其中加了 [] ，如 qemu64, kvm64 等CPU模型是 QEMU命令中原生自带 (built-in) 的，现在所有的定义都放在 target-i386/cpu.c 文件中

- 尽可能多地将物理CPU信息暴露给客户机
        
	-cpu host

- 改变 qemu64 类型CPU的默认类型
        
	-cpu qemu64,model=13

- 可以用一个 CPU模型作为基础，然后用“+”号将部分的CPU特性添加到基础模型中去
        
	-cpu qemu64,+avx

# 5. 进程的处理器亲和性和 vCPU 的绑定 #
   
注：特别是在多处理器、多核、多线程技术使用的情况下，在NUMA结构的系统中，如果不能基于对系统的CPU、内存等有深入的了解，对进程的处理器亲和性进行设置导致系统的整体性能的下降而非提升。

## 5.1 隔离 CPU ##
     vi grub.cfg
      title Red Hat ........
            root (hd0,0)
            kernel /boot/vmlinuz-3.8 ro root=UUID=****** isoplus=2,3

    检查是否隔离成功，第一行的输出明显大于2、3行。
            ps -eLO psr | grep 0 | wc -l 
            ps -eLO psr | grep 2 | wc -l
            ps -eLO psr | grep 3 | wc -l

## 5.2 启动一个客户机 ##
    
	qemu-system-x86_64 rhel6u3.img -smp 2 -m 512 -daemonize

## 5.3 绑定 vCPU ##
KVM

- 查看代表 vCPU 的QEMU进程

    ps -eLo ruser,pid,ppid,lwp,psr,args | grep qemu | grep -v grep

- 绑定代表整个客户机的 QEMU 进程，使其运行在 cpu2/cpu3 上，其中 3963为 qemu主线程、3967和3968分别为两个 vCPU.

    taskset -p 0x4 3963
    taskset -p 0x4 3967
    taskset -p 0x8 3968

- 查看绑定是否有效
       
	ps -eLo ruser,pid,ppid,lwp,psr,args | grep qemu | awk '{if$5==2 print $0}'
    Ctrl + Alt +2 -->  info cpus

XEN how to use vcpu pin cpu

	#!/bin/bash
	domid=$1
	cpus_num=$2
	for i in `seq 0 $cpus_num`
	do
	xl vcpu-pin $domid $i $i
	done

you can put this in the vm config
	
cpus="CPU-LIST"

	List of which cpus the guest is allowed to use. Default is no pinning at all (more on this below). A "CPU-LIST" may be specified as follows:
	"all"
	    To allow all the vcpus of the guest to run on all the cpus on the host.
	
	"0-3,5,^1"
	    To allow all the vcpus of the guest to run on cpus 0,2,3,5. Combining this with "all" is possible, meaning "all,^7" results in all the vcpus of the guest running on all the cpus on the host except cpu 7.



CPU Hotplug Support in QEMU
-----
[1] http://www.linux-kvm.org/images/0/0c/03x07A-Bharata_Rao_and_David_Gibson-CPU_Hotplug_Support_in_QEMU.pdf
[2] https://www.youtube.com/watch?v=WuTPq8XgEbY
