## me introduction

- C and Server
- Linux Kernel and Programming
- Shell and Python
- KVM/Xen
- X86

## Compile Cloud

Compile VM: dstat(network send, disk read/write) 
Link VM: dstat(network receive, disk write)

network: iperf ( network cable/100m, switch )
disk io: fio (cat /sys/block/sda/queue/scheduler), disk array(write through), ssd too full

KVM can create more VM.


## S2L USB

			 EP1                             EP2 
	
	User
             ioctl                          ioctl
		   ----------------------------------------- 
	Kernel  | | | |                        | | | |
             
               |                              ^
               V                              |
             Driver ----------------------> Driver   

- perf top: ioctl function, move split package from user to kernel.
- spinlock, list, big array (index, read index and write index add spinlock)
- Cache 32bit align: data error.
- usb protocol: transfer sync model to transfer bulk model.  

## intel feature

skylake:Local MCE and TSC test method
knm:288vcpus\pmu\numadistances\ominipath\system topology\mcdram
icx:sgx,spp



## performance
### iperf

### fio

http://blog.yufeng.info/archives/2104

https://www.linux.com/learn/inspecting-disk-io-performance-fio

	cat random-read-test.fio
	[random-read]
	rw=randread
	size=128m
	directory=/fio-testing/data
	
	fio random-read-test.fio

Fio 是个强大的IO压力测试工具，我之前写过不少fio的使用和实践，参见 这里。

随着块设备的发展，特别是SSD盘的出现，设备的并行度越来越高。利用好这些设备，有个诀窍就是提高设备的iodepth, 一把喂给设备更多的IO请求，让电梯算法和设备有机会来安排合并以及内部并行处理，提高总体效率。

应用使用IO通常有二种方式：同步和异步。 同步的IO一次只能发出一个IO请求，等待内核完成才返回，这样对于单个线程iodepth总是小于1，但是可以透过多个线程并发执行来解决，通常我们会用16-32根线程同时工作把iodepth塞满。 异步的话就是用类似libaio这样的linux native aio一次提交一批，然后等待一批的完成，减少交互的次数，会更有效率。

io队列深度通常对不同的设备很敏感，那么如何用fio来探测出合理的值呢？

### perf
http://www.brendangregg.com/perf.html

perf record
perf report
perf top

### dstat
n/a

### speccpu

### specjbb
http://blog.csdn.net/guofu8241260/article/details/9232747

### lmbench