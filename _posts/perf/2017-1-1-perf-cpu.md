# 1. CPU性能测试 #
## 1.1 Super_PI ##
https://zh.wikipedia.org/wiki/Super_PI

http://superpi.ilbello.com/pi/super_pi.tar.bz2

Super PI被许多超频玩家用以测试电脑的性能及稳定性。在超频社区中，常规的程序为电脑爱好者提供基准测试以比较圆周率计算“世界纪录”并展示超频能力。该程序也被用来测定某一超频速率下的稳定性。如果一台电脑能够准确计算圆周率至小数点以后3200万位，就被认为在一定的RAM和CPU环境下具有稳定性。然而，其它CPU/RAM增强运算程序运行时间往往持续几个小时而不是几分钟并且可能会给系统稳定性带来更多压力。尽管Super PI并非计算圆周率最快的程序，但它仍在硬件及超频社区中广为流传。

Super PI采用单线程，因此其作为目前多核心处理器性能指标的测试工具的意义迅速降低。因此，Hyper PI被开发出来以支持多线程Super PI同时运行而能在多核心设备测试稳定性。其他的多线程程序有：wPrime、IntelBurnTest、Prime95、Montecarlo superPI、OCCT。

## 1.2 Spec cpu

https://www.spec.org/benchmarks.html#cpu

## 1.3 Sysbench

http://imysql.com/2014/10/17/sysbench-full-user-manual.shtml

sysbench是一个模块化的、跨平台、多线程基准测试工具，主要用于评估测试各种不同系统参数下的数据库负载情况。
目前sysbench代码托管在launchpad上，项目地址：https://launchpad.net/sysbench（原来的官网 http://sysbench.sourceforge.net 已经不可用），源码采用bazaar管理。

sysbench支持以下几种测试模式：

- CPU运算性能
- 磁盘IO性能
- 调度程序性能
- 内存分配及传输速度
- POSIX线程性能
- 数据库性能(OLTP基准测试)
目前sysbench主要支持 mysql,drizzle,pgsql,oracle 等几种数据库。

## 1.4 cyclesoak
http://www.stlinux.com/devel/traceprofile/cyclesoak

## 1.5 HPC
spec hpc: https://www.spec.org/hpc2002/  
open-mpi: https://www.open-mpi.org/

## 1.6 stress
https://linux.die.net/man/1/stress

# 2. CPU 性能优化 #
## 2.1 中断亲和性

不同的设备一般都有自己的IRQ号码（当然一个设备还有可能有多个IRQ号码）

通过如下命令可查看：
如：cat /proc/interrupts | grep -e “CPU\|eth4”

中断的smp affinity在cat  /proc/irq/$Num/smp_affinity，可以 echo “$bitmask” > /proc/irq/$num/smp_affinity来改变它的值。

注意smp_affinity这个值是一个十六进制的bitmask，它和cpu No.序列的“与”运算结果就是将affinity设置在那个（那些）CPU了。（也即smp_affinity中被设置为1的位为CPU No.）

比如：我有8个逻辑core，那么CPU#的序列为11111111 （从右到左依次为#0~#7的CPU）

如果cat  /proc/irq/84/smp_affinity的值为：20（二进制为：00100000），则84这个IRQ的亲和性为#5号CPU。

每个IRQ的默认的smp affinity在这里：cat /proc/irq/default_smp_affinity

另外，cat  /proc/irq/$Num/smp_affinity_list 得到的即是CPU的一个List。

默认情况下，有一个irqbalance在对IRQ进行负载均衡，它是/etc/init.d/irqbalance
在某些特殊场景下，可以根据需要停止这个daemon进程。

## 2.2 设置 CPU的亲和性 ##
如果要想提高性能，将IRQ绑定到某个CPU，那么最好在系统启动时，将那个CPU隔离起来，不被scheduler通常的调度。

可以通过在Linux kernel中加入启动参数：isolcpus=cpu-list来将一些CPU隔离起来。

### 2.2.1 概念
什么是CPU Affinity？Affinity是进程的一个属性，这个属性指明了进程调度器能够把这个进程调度到哪些CPU上。
在Linux中，我们可以利用CPU affinity 把一个或多个进程绑定到一个或多个CPU上。CPU Affinity分为2种，soft affinity和hard affinity。soft affinity仅是一个建议，如果不可避免，调度器还是会把进程调度到其它的CPU上。hard affinity是调度器必须遵守的规则。

为什么需要CPU绑定？

- 增加CPU缓存的命中率

CPU之间是不共享缓存的，如果进程频繁的在各个CPU间进行切换，需要不断的使旧CPU的cache失效。如果进程只在某个CPU上执行，则不会出现失效的情况。

- 增加CPU缓存的命中率

 在多个线程操作的是相同的数据的情况下，如果把这些线程调度到一个处理器上，大大的增加了CPU缓存的命中率。但是可能会导致并发性能的降低。如果这些线程是串行的，则没有这个影响。

- 适合time-sensitive应用

 在real-time或time-sensitive应用中，我们可以把系统进程绑定到某些CPU上，把应用进程绑定到剩余的CPU上。典型的设置是，把应用绑定到某个CPU上，把其它所有的进程绑定到其它的CPU上。

### 2.2.2 绑定进程和CPU的编码实现 ###
进程亲和性的设置和获取主要通过下面两个函数来实现：

	#define _GNU_SOURCE
	#include <sched.h>long sched_setaffinity(pid_t pid, unsigned int len,unsigned long *user_mask_ptr);
	long sched_getaffinity(pid_t pid, unsigned int len,unsigned long *user_mask_ptr);

### 2.2.3 绑定线程和CPU的编码实现 ###
与进程的情况相似，线程亲和性的设置和获取主要通过下面两个函数来实现：

	int pthread_setaffinity_np(pthread_t thread, size_t cpusetsize，const cpu_set_t *cpuset);
	int pthread_getaffinity_np(pthread_t thread, size_t cpusetsize, cpu_set_t *cpuset);

从函数名以及参数名都很明了，唯一需要点解释下的可能就是cpu_set_t这个结构体了。这个结构体的理解类似于select中的fd_set，可以理解为cpu集，也是通过约定好的宏来进行清除、设置以及判断：

  //初始化，设为空             void CPU_ZERO (cpu_set_t *set);       
  //将某个cpu加入cpu集中       void CPU_SET (int cpu, cpu_set_t *set);        
  //将某个cpu从cpu集中移出     void CPU_CLR (int cpu, cpu_set_t *set);        
  //判断某个cpu是否已在cpu集中设置了  int CPU_ISSET (int cpu, const cpu_set_t *set);

cpu集可以认为是一个掩码，每个设置的位都对应一个可以合法调度的 cpu，而未设置的位则对应一个不可调度的 CPU。换而言之，线程都被绑定了，只能在那些对应位被设置了的处理器上运行。通常，掩码中的所有位都被置位了，也就是可以在所有的cpu中调度。

### 2.2.4 进程独占CPU ###

如何实现一个或多个进程独占一个或多个CPU？ 即调度器只能把指定的进程调度至指定的CPU。最简单的方法是利用fork()的继承特性，子进程继承父进程的affinity。这种方法无需修改和编译内核代码。

init进程是所有进程的祖先，我们可以设置init进程的affinity来达到设置所有进程的affinity的目地，然后把我们自己的进程绑定到目地CPU上。这样就到达了在指定CPU上只运行指定的的进程的目地。

那么，如何修改init进程的affinity？我们只需在/etc/rc.d/rc.sysinit或/etc/rc.sysinit中，起始处增加如下两行，其中bind是5.1小节编译生成的可执行文件，rc.sysinit文件是init进程运行的第一个脚本。

/bin/bind 1 1   #绑定init进程至处理器0
/bin/bind $$ 1  #绑定当前进程至处理器0

### 2.2.5 源代码 ###
#### 5.1 绑定进程 ####
	/* bind - simple command-line tool to set CPU * affinity of a given task */#define _GNU_SOURCE
	#include <stdlib.h>
	#include <stdio.h>
	#include <sched.h>
	int main(int argc, char *argv[]){    
	    unsigned long new_mask;    
	    unsigned long cur_mask;    
	    unsigned int len = sizeof(new_mask);    
	    pid_t pid;     
	    if (argc != 3) {   
	        fprintf(stderr, "usage: %s [pid] [cpu_mask]\n",  argv[0]);   
	        return -1;    
	    }     
	    pid = atol(argv[1]);    
	    sscanf(argv[2], "%08lx", &new_mask);     
	    if (sched_getaffinity(pid, len,&cur_mask) < 0) {  
	        perror("sched_getaffinity");   
	        return -1;    
	     }     
	     printf("pid %d's old affinity: %08lx\n",pid, cur_mask);     
	     if (sched_setaffinity(pid, len, &new_mask)) {   
	         perror("sched_setaffinity");   
	         return -1;    
	     }     

	     if (sched_getaffinity(pid, len, &cur_mask) < 0) {  
	             perror("sched_getaffinity");   
	             return -1;    
	     }     

	     printf(" pid %d's new affinity: %08lx\n", \pid, cur_mask);     
	     return 0;
	 }

#### 5.2 绑定线程 ####

	#define _GNU_SOURCE
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <unistd.h>
	#include <pthread.h>
	#include <sched.h> void *myfun(void *arg)
	{    
	    cpu_set_t mask;    
	    cpu_set_t get;    
	    char buf[256];    
	    int i;   
	    int j;    
	    int num = sysconf(_SC_NPROCESSORS_CONF);    
	    printf("system has %d processor(s)\n", num);     
	    for (i = 0; i < num; i++) {        
	        CPU_ZERO(&mask);        
	        CPU_SET(i, &mask);        
	        if (pthread_setaffinity_np(pthread_self(), sizeof(mask), &mask) < 0) {            
	            fprintf(stderr, "set thread affinity failed\n");        
	        }        
	        CPU_ZERO(&get);        
	        if (pthread_getaffinity_np(pthread_self(), sizeof(get), &get) < 0) {            
	            fprintf(stderr, "get thread affinity failed\n");        
	        }        
	        for (j = 0; j < num; j++) {            
	            if (CPU_ISSET(j, &get)) {                
	                printf("thread %d is running in processor %d\n", (int)pthread_self(), j);            
	            }        
	        }        
	        j = 0;        
	        while (j++ < 100000000) {            
	            memset(buf, 0, sizeof(buf));        
	         }    
	       }   
	        pthread_exit(NULL);
	    }

	int main(int argc, char *argv[]){    

	         pthread_t tid;    

	         if (pthread_create(&tid, NULL, (void *)myfun, NULL) != 0) {        
	            fprintf(stderr, "thread create failed\n");       
	             return -1;    
	         }   

	         pthread_join(tid, NULL);  
	         return 0;
	}

#### 5.3 mpstat

	mpstat -P ALL -u 1 10 显示CPU使用率
	mpstat -P ALL -I ALL 1 10显示中断信息

#### 5.4.pidstat

	pidstat -p 'pid' 1 10
	pidstat -p 'pid' -t -w 1 10 进程和线程的上下文切换次数

# 3. 参考资料 #

http://kernel.org/doc/Documentation/IRQ-affinity.txt

http://kernel.org/doc/Documentation/kernel-parameters.txt

http://www.vpsee.com/2010/07/load-balancing-with-irq-smp-affinity/
