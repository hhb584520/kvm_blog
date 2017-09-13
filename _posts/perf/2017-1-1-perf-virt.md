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

### 2.3 基础调优

#### 2.3.1 基本调优
- 裸设备
- SR-IOV
- 中断 round-robin，host中断
- vhost-blk        磁盘I/O不走Qemu
- fpu                    协处理器不退出，增加浮点运算效率
- up                    Guest当前是多核
- 关闭 ttwu_queue，减少res中断
- 更新 /etc/sysctl.conf

		net.core.somaxconn=8192
		net.ipv4.tcp_max_tw_buckets=500000
		net.ipv4.conf.default.arp_filter=1
		net.ipv4.conf.all.arp_filter=1
		net.core.netdev_max_blocklog=500000
		kernel.sched_min_granularity_ns=10000000
		kernel.sched_wakeup_granularity_ns=15000000
		kernel.sched_shares_ratelimit=10000000
		fs.aio-max-nr=70656
		--> In /etc/security/limits.conf
		hard and soft nofile set to 102400
		hard and soft nproc set to 102400

- Qemu进程启动虚拟机
- PVEOI (中断应答不退出)
- PREEMPT_VOLUNTARY
- dataplane
- 1G大页表
- idle = halt
- 内核3.8 + host去掉 netfilter模块

#### 2.3.2 无时钟设置
说明：
nohz_full 这个参数加上是和用意
它不是用来指定哪些 CPU核心可以进入完全无滴答状态，指定的cpu不会处理来自时钟的中断
这些CPU是给guest用的 ，如果这些cpu要处理timer的中断, 那么肯定会影响guest中vcpu的性能



https://access.redhat.com/documentation/zh-CN/Red_Hat_Enterprise_Linux/7/html/Performance_Tuning_Guide/sect-Red_Hat_Enterprise_Linux-Performance_Tuning_Guide-CPU-Configuration_suggestions.html

**编译内核**

Host kernel must be compiled with CONFIG_NO_HZ_FULL=y configuration option.
In order to check this, you can execute the following command:
grep CONFIG_NO_HZ_FULL “/boot/config-$(uname –r)”


**配置内核滴答记号时间**

默认情况下，红帽企业版 Linux 7 使用无时钟内核，它不会中断空闲 CPU 来减少用电量，并允许较新的处理器利用深睡眠状态。 

红帽企业版 Linux 7 同样提供一种动态的无时钟设置（默认禁用），这对于延迟敏感型的工作负载来说是很有帮助的，例如高性能计算或实时计算。 

要启用特定内核中的动态无时钟性能，在内核命令行中用 nohz_full 参数进行设定。在 16 核的系统中，设定 nohz_full=1-15 可以在 1 到 15 内核中启用动态无时钟内核性能，并将所有的计时移动至唯一未设定的内核中（0 内核）。这种性能可以在启动时暂时启用，也可以在 /etc/default/grub 文件中永久启用。要持续此性能，请运行 grub2-mkconfig -o /boot/grub2/grub.cfg 指令来保存配置。 

启用动态无时钟性能需要一些手动管理。 


当系统启动时，必须手动将 rcu 线程移动至对延迟不敏感的内核，这种情况下为 0 内核。 

	$ for i in `pgrep rcu` ; do taskset -pc 0 $i ; done


在内核命令行上使用 isolcpus 参数来将特定的内核与用户空间任务隔离开。 

可以选择性地为辅助性内核设置内核回写式 bdi-flush 线程的 CPU 关联： 
echo 1 > /sys/bus/workqueue/devices/writeback/cpumask

我们可以配置如下：
nohz_full=2-67,70-135,138-203,206-271 isolcpus=2-67,70-135,138-203,206-271


**验证动态无时钟配置是否正常运行**

执行以下命令，其中 stress 是在 CPU 中运行 1 秒的程序。 

	$ perf stat -C 1 -e irq_vectors:local_timer_entry taskset -c 1 stress -t 1 -c 1

可替代 stress 的是一个脚本，该脚本的运行类似 while :; do d=1; done 。以下链接中的程序是另一个合适的替代程序： https://dl.fedoraproject.org/pub/epel/6/x86_64/repoview/stress.html。 

默认的内核计时器配置在繁忙 CPU 中显示 1000 次滴答记号： 

	$ perf stat -C 1 -e irq_vectors:local_timer_entry taskset -c 1 stress -t 1 -c 1
	1000 irq_vectors:local_timer_entry

动态无时钟内核配置下，用户只会看到一次滴答记号： 

	$ perf stat -C 1 -e irq_vectors:local_timer_entry taskset -c 1 stress -t 1 -c 1
	1 irq_vectors:local_timer_entry



### 2.4 高级调优
- MKL & MPI library version

Mkl:  parallel_studio_xe_2016_update3
MPI: mpi_2017.1.132

- Host & Guest kernel cmdline parameter

Host:  crashkernel=auto console=tty0 console=ttyS0,115200,8n1 3 intel_iommu=on LANG=en_US.UTF-8 nohz_full=2-63,66-127,130-191,194-255 isolcpu=2-63,66-127,130-191,194-255 intel_pstate=disable idle=halt
Guest:  crashkernel=auto rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap console=ttyS0 nohz_full=1-239 idle=halt

- Guest configuration script

qemu-system-x86_64 -enable-kvm -cpu host -m 100G -smp cpus=240,cores=60,threads=4,sockets=1 -drive format=qcow2,file=/rhel7u2_kvm_common.qcow2,index=0,media=disk -object memory-backend-ram,size=85G,prealloc=yes,host-nodes=0,policy=bind,id=node0 -numa node,nodeid=0,cpus=0-239,memdev=node0 -object memory-backend-ram,size=15G,prealloc=yes,host-nodes=1,policy=bind,id=node1 -numa node,nodeid=1,memdev=node1 -netdev user,id=network0 -device e1000,netdev=network0 -name vmm,process=vmm,debug-threads=on -serial stdio

- ‘numactl –H’ info in guest

	available: 2 nodes (0-1)
	node 0 cpus: 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239
	node 0 size: 87039 MB
	node 0 free: 82963 MB
	node 1 cpus:
	node 1 size: 15360 MB
	node 1 free: 2447 MB
	node distances:
	node   0   1
	  0:  10  20
	  1:  20  10

- Vcpu pin way

Use pin_sh you send to me
 
	#!/bin/sh
	output=$(ps -T -p `pgrep vmm`)
	while read -r line
	do
	#  13960  14203 pts/3    00:00:02 CPU 239/KVM
	    cols=($line)
	    if [ "${cols[4]}" = "CPU" ]; then
	                    cpu=$(echo ${cols[5]} | cut -d / -f1)
	                    thread=${cols[1]}
	                    pcpu=$((2 + cpu / 4 + cpu % 4 * 64))
	                    taskset -pc $((pcpu)) $((thread))
	    elif [ "${cols[4]}" = "qemu-system-x86" ]; then
	                    kvm_thread=${cols[0]}
	                    taskset -cp 0,1,64,65,128,129,192,193 $((kvm_thread))
	                    taskset -cp 0,1,64,65,128,129,192,193 $((kvm_thread+1))
	    fi
	done <<< "$output"


XML格式：

	<domain type='kvm'>
	  <name>vmm</name> 
	  <memory unit='GiB'>96</memory>  
	  <vcpu placement='static'>244</vcpu> 
	  <cpu mode='host-passthrough'> 
	    <numa>
	      <cell id='0' cpus='0-239' memory='80' unit='GiB'/> 
	      <cell id='1' cpus='240-243' memory='16' unit='GiB'/> 
	    </numa>
	    <topology sockets="1" cores="61" threads="4" /> 
	  </cpu>
	
	  <numatune>
	    <memnode cellid='0' mode='strict' nodeset='0'/> 
	    <memnode cellid='1' mode='strict' nodeset='1'/>
	  </numatune>
	
	  <os>
	    <type arch='x86_64' machine='pc'>hvm</type> 
	    <boot dev='hd'/>
	  </os>
	
	  <features>
	      <acpi /> 
	      <apic /> 
	  </features>
	
	  <devices>
	    <disk type='file' device='disk'> 
	      <driver name='qemu' type='qcow2'/>
	      <source file='/tmp/tests/vm/rh72small/tmp-img'/>
	      <target dev='hda' bus='ide'/>
	      <address type='drive'/>
	    </disk>
	    <interface type='network'> 
	      <source network='default' />
	    </interface>
	    <graphics type="vnc"/> 
	  </devices>
	
	  <cputune> <!-- pin vCPUs to physical CPUs -->
	    <vcpupin vcpu='0' cpuset='2'/> 
	    <vcpupin vcpu='1' cpuset='70' />
	    <vcpupin vcpu='2' cpuset='138' />
	    <vcpupin vcpu='3' cpuset='206' />
	    <vcpupin vcpu='4' cpuset='3' /> 
	    <vcpupin vcpu='5' cpuset='71' />
	    <vcpupin vcpu='6' cpuset='139' />
	<vcpupin vcpu='7' cpuset='207' />
	……
	    <vcpupin vcpu='240' cpuset='62' />
	    <vcpupin vcpu='241' cpuset='130' />
	    <vcpupin vcpu='242' cpuset='198' />
	    <vcpupin vcpu='243' cpuset='266' />
	  </cputune>
	</domain>


- set task affinity

**kvmparse.py**: 

	import os
	import sys
	
	f = open(sys.argv[1], 'r')
	for l in f:
	    fields = l.rstrip().split()
	
	#  8165   8375 pts/0    00:00:05 CPU 206/KVM
	    if fields[4] == "CPU":
	        cpu = int(fields[5].split('/')[0])
	        #print fields[1], cpu
	        core = cpu/4
	        ht = cpu%4
	        newcpu = 2 + core + ht*68
	        print "taskset -pc " + str(newcpu) + " " + fields[1]


If libvirt is unavailable or is not a preferred choice, qemu emulator may be used directly.
First launch virtual machine using command line below:

/usr/local/bin/qemu-system-x86_64 -enable-kvm \
    -m 96G -cpu host \
    -smp cpus=240,cores=60,threads=4,sockets=1 \
    -drive format=raw,file=/home/lfmeadow/qemu/legacy.img,index=0,media=disk \
    -object memory-backend-ram,size=80G,prealloc=yes,host-nodes=0,policy=bind,id=node0 \
    -numa node,nodeid=0,cpus=0-239,memdev=node0 \
    -object memory-backend-ram,size=16G,prealloc=yes,host-nodes=1,policy=bind,id=node1 \
    -numa node,nodeid=1,memdev=node1 \
    -netdev user,id=network0 -device e1000,netdev=network0 \
    -name vmm,process=vmm,debug-threads=on \
    -serial stdio –sdl

The following table explains each of the options
Now launch another terminal window and run the following commands:
ps -T -p `pgrep vmm` >/tmp/t
python kvmparse.py /tmp/t >/tmp/pin
sh /tmp/pin
The first command assumes you’ve named your VM process vmm and stores list of its threads to /tmp/t. 
Then with python script kvmparse.py (Appendix A) this list is converted to commands that pin threads representing virtual CPUs to corresponding physical CPUs. Finally, the commands are run.
New terminal window can now be closed. To resume VM type “cont” in qemu console and go back to VM in SDL window using “ctrl-alt-1”.
