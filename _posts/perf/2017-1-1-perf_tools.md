##﻿﻿﻿﻿ 1. Perf介绍 ##

Perf 最全介绍 http://www.brendangregg.com/perf.html

### 1.1 Perf 简介 ###
Perf 是用来进行软件性能分析的工具。通过它，应用程序可以利用 PMU，tracepoint 和内核中的特殊计数器来进行性能统计。它不但可以分析指定应用程序的性能问题 (per thread)，也可以用来分析内核的性能问题，当然也可以同时分析应用代码和内核，从而全面理解应用程序中的性能瓶颈。最初的时候，它叫做 Performance counter，在 2.6.31 中第一次亮相。此后他成为内核开发最为活跃的一个领域。在 2.6.32 中它正式改名为 Performance Event，因为 perf 已不再仅仅作为 PMU 的抽象，而是能够处理所有的性能相关的事件。

性能调优工具如 perf，Oprofile 等的基本原理都是对被监测对象进行采样，最简单的情形是根据 tick 中断进行采样，即在 tick 中断内触发采样点，在采样点里判断程序当时的上下文。假如一个程序 90% 的时间都花费在函数 foo() 上，那么 90% 的采样点都应该落在函数 foo() 的上下文中。运气不可捉摸，但我想只要采样频率足够高，采样时间足够长，那么以上推论就比较可靠。因此，通过 tick 触发采样，我们便可以了解程序中哪些地方最耗时间，从而重点分析。稍微扩展一下思路，就可以发现改变采样的触发条件使得我们可以获得不同的统计数据：

- 以时间点 ( 如 tick) 作为事件触发采样便可以获知程序运行时间的分布。
- 以 cache miss 事件触发采样便可以知道 cache miss 的分布，即 cache 失效经常发生在哪些程序代码中。如此等等。

使用 perf，主要可以分析几类事件：

- perf list hw
- perf list sw
- perf list cache
- perf list pmu
- perf list tracepoint

### 1.2 PMU ###
PMU

其中三个事件是fixed counter（固定计数器，参考18.4.1 Fixed-function Performance Counters了解其概念），简单理解它们用于计数对应的预定义的一些事件。
1. CPU_CLK_UNHALTED
Programable counter version of the unhalted cycle counter
表示非停机状态的机器周期数。
很显然，对于一个程序，这个事件的数目越少越好，表明其运行状态(非停机状态)消耗的机器周期少，即耗时少。其有三个扩展：
THREAD_P：非停机状态下线程的机器周期。线程在运行HLT指令的时候进入halt state(停机状态)。由于CPU核的频率会不断变化，这个事件数目和时间的比例是变化的。
TOTAL_CYCLES：CPU机器周期数目的总和，halted+unhalted（除了处于深度睡眠状态）。
REF_P：线程在非停机状态下，计数base clock(133Mhz)的参考机器周期数目。很显然，这个事件不会被频率影响，就好象是线程运行一直运行在一个最大的频率一样。

2. CPU_CLK_UNHALTED.REF
Reference cycles when thread is not halted (fixed counter)
和上面的CPU_CLK_UNHALTED的REF_P的含义相同。

3. CPU_CLK_UNHALTED.THREAD
Cycles when thread is not halted (fixed counter)
和上面的CPU_CLK_UNHALTED的THREAD_P的含义相同。

4. INST_RETIRED.ANY
Instructions retired ( fixed counter ) 
表示消耗的指令数，计数执行过程中消耗的指令数。
说明：关于retire，一般表示退休什么的意思，这里其实其含义就是“消耗”，retirement表示指令隐退，或者可以理解为其技术指令从执行到退出的那个退出的次数，自然，其实就表示消耗的指令数了。:)
对于包含多个微操作(micro-op)的指令，其只对最后一个微操作的指令引退进行计数，即只计数一次。

5. THREAD_ACTIVE
Cycles thread is active
线程处于active状态下的机器周期数。


性能指标之CPI：
Clockticks per Instructions Retired (CPI)
即Cycles per Instructions，表示每一条指令消耗的时钟周期。这是一个基础的性能指标之一，在进行性能分析时，其一般是首先会分析的一个指标。
很显然，CPI的值越小越好，CPI的计算为：Clockticks / Instructions Retired。如：
CPI=CPU_CLK_UNHALTED.THREAD/INST_RETIRED.ANY
说明：如果要计算一个函数的CPI，就使用相应的事件计算，这里的例子是计算整个thread的CPI。
根据经验值，如果CPI小于0.75，那么认为其性能是不错的。如果大于0.75，就需要考虑进行优化了。 

## 2. Perf安装 ##
### 2.1 Perf编译 ###
安装 perf 非常简单，只要您有 2.6.31 以上的内核源代码，那么进入 tools/perf 目录然后敲入下面两个命令即可：

	 make 
	 make install
 
	 ------ arm ------
	 make V=2 ARCH=arm NO_DWARF=1 NO_LIBPERL=1 NO_LIBPYTHON=1 NO_DEMANGLE=1 NO_NEWT=1 NO_OPENSSL=1 NO_SVN_TESTS=1 
	NO_IPV6=1 NO_ICONV=1 CROSS_COMPILE=~/nfs1/toolchains/arm-2013.05/bin/arm-none-linux-gnueabi-

### 2.2 Perf对应内核编译 ###

内核添加： PERF_EVENTS

### 2.3 Perf界面安装 ###
Perf 提供了3种用户界面，分别是tui,gtk以及tty。其中可操作性最强，功能最丰富的界面是tui。要使用tui，必须在系统安装newt软件包，在tui界面下按 ‘h'，’？‘或F1键时，会弹出一个帮组窗口。

## 3. 应用性能分析 ##
### 3.1 Perf 的基本使用 ###
说明一个工具的最佳途径是列举一个例子。
考查下面这个例子程序。其中函数 longa() 是个很长的循环，比较浪费时间。函数 foo1 和 foo2 将分别调用该函数 10 次，以及 100 次。
清单 1. 测试程序 t1

	 //test.c 
	 void longa() 
	 { 
	   int i,j; 
	   for(i = 0; i < 1000000; i++) 
	   j=i; //am I silly or crazy? I feel boring and desperate. 
	 } 
	
	 void foo2() 
	 { 
	   int i; 
	   for(i=0 ; i < 10; i++) 
	        longa(); 
	 } 
	
	 void foo1() 
	 { 
	   int i; 
	   for(i = 0; i< 100; i++) 
	      longa(); 
	 } 
	
	 int main(void) 
	 { 
	   foo1(); 
	   foo2(); 
	 }

找到这个程序的性能瓶颈无需任何工具，肉眼的阅读便可以完成。Longa() 是这个程序的关键，只要提高它的速度，就可以极大地提高整个程序的运行效率。
但，因为其简单，却正好可以用来演示 perf 的基本使用。假如 perf 告诉您这个程序的瓶颈在别处，您就不必再浪费宝贵时间阅读本文了。

### 3.2 Perf list，perf 事件 ###
使用 perf list 命令可以列出所有能够触发 perf 采样点的事件。比如

    List all symbolic event types.
    perf list [hw | sw | cache | tracepoint | pmu]

(1) 性能事件的分布

    hw：Hardware event，9个 是由PMU硬件产生的事件，比如cache命中，当您需要了解程序对硬件特性的使用情况时，便需要对这些事件进行采样；
    sw：Software event，9个 是内核软件产生的事件，比如进程切换，tick数等；
    cache：Hardware cache event，26个
    tracepoint：Tracepoint event，775个 是内核中的静态 tracepoint所触发的事件，这些事件用于判断程序运行期间内核的行为细节，比如slab分配器的分配次数等。
    sw实际上是内核的计数器，与硬件无关。
    hw和cache是CPU架构相关的，依赖于具体硬件。
    tracepoint是基于内核的ftrace，主线2.6.3x以上的内核版本才支持。

(2) 指定性能事件(以它的属性)

    -e <event> : u // userspace
    -e <event> : k // kernel
    -e <event> : h // hypervisor
    -e <event> : G // guest counting (in KVM guests)
    -e <event> : H // host counting (not in KVM guests)
    -e <event> : p // 精度控制

(3) 使用例子

    显示内核和模块中，消耗最多CPU周期的函数：
        # perf top -e cycles:k
    显示分配高速缓存最多的函数：
        # perf top -e kmem:kmem_cache_alloc
    我们想统计所有从内存中读过数据的指令的个数，perf list中并未预定义此事件的字符描述。通过查找 Intel的处理器手册，我们找到了此事件的编码：
    perf top -e -r[UMask:EventSelect]    

### 3.3 Perf stat ###

面对一个问题程序，最好采用自顶向下的策略。先整体看看该程序运行时各种统计事件的大概，再针对某些方向深入细节。而不要一下子扎进琐碎细节，会一叶障目的。有些程序慢是因为计算量太大，其多数时间都应该在使用 CPU 进行计算，这叫做 CPU bound 型；有些程序慢是因为过多的 IO，这种时候其 CPU 利用率应该不高，这叫做 IO bound 型；对于 CPU bound 程序的调优和 IO bound 的调优是不同的。如果您认同这些说法的话，Perf stat 应该是您最先使用的一个工具。它通过概括精简的方式提供被调试程序运行的整体情况和汇总数据。
还记得我们前面准备的那个例子程序么？现在将它编译为可执行文件 t1

	gcc – o t1 – g test.c

(1) 输出格式
下面演示了 perf stat 针对程序 t1 的输出：

	 $perf stat ./t1 
	 Performance counter stats for './t1': 
	
	 262.738415 task-clock-msecs # 0.991 CPUs 
	 2 context-switches # 0.000 M/sec 
	 1 CPU-migrations # 0.000 M/sec 
	 81 page-faults # 0.000 M/sec 
	 9478851 cycles # 36.077 M/sec (scaled from 98.24%) 
	 6771 instructions # 0.001 IPC (scaled from 98.99%) 
	 111114049 branches # 422.908 M/sec (scaled from 99.37%) 
	 8495 branch-misses # 0.008 % (scaled from 95.91%) 
	 12152161 cache-references # 46.252 M/sec (scaled from 96.16%) 
	 7245338 cache-misses # 27.576 M/sec (scaled from 95.49%) 
	
	  0.265238069 seconds time elapsed 

上面告诉我们，程序 t1 是一个 CPU bound 型，因为 task-clock-msecs 接近 1。
对 t1 进行调优应该要找到热点 ( 即最耗时的代码片段 )，再看看是否能够提高热点代码的效率。
缺省情况下，除了 task-clock-msecs 之外，perf stat 还给出了其他几个最常用的统计信息：

    Task-clock-msecs：CPU 利用率，该值高，说明程序的多数时间花费在 CPU 计算上而非 IO。
    Context-switches：进程切换次数，记录了程序运行过程中发生了多少次进程切换，频繁的进程切换是应该避免的。
    Cache-misses：程序运行过程中总体的 cache 利用情况，如果该值过高，说明程序的 cache 利用不好
    CPU-migrations：表示进程 t1 运行过程中发生了多少次 CPU 迁移，即被调度器从一个 CPU 转移到另外一个 CPU 上运行。
    Cycles：处理器时钟，一条机器指令可能需要多个 cycles，
    Instructions: 机器指令数目。
    IPC：是 Instructions/Cycles 的比值，该值越大越好，说明程序充分利用了处理器的特性。
    Cache-references: cache 命中的次数
    Cache-misses: cache 失效的次数。
    branches：遇到的分支指令数。branch-misses是预测错误的分支指令数。
    通过指定 -e 选项，您可以改变 perf stat 的缺省事件 ( 关于事件，在上一小节已经说明，可以通过 perf list 来查看 )。假如您已经有很多的调优经验，可能会使用 -e 选项来查看您所感兴趣的特殊的事件。

用于分析指定程序的性能概况。

	perf record -g -a ./test
	perf report

(2) 常用参数

	-p：stat events on existing process id (comma separated list). 仅分析目标进程及其创建的线程。
	-a：system-wide collection from all CPUs. 从所有CPU上收集性能数据。
	-r：repeat command and print average + stddev (max: 100). 重复执行命令求平均。
	-C：Count only on the list of CPUs provided (comma separated list), 从指定CPU上收集性能数据。
	-v：be more verbose (show counter open errors, etc), 显示更多性能数据。
	-n：null run - don't start any counters，只显示任务的执行时间 。
	-x SEP：指定输出列的分隔符。
	-o file：指定输出文件，--append指定追加模式。
	--pre <cmd>：执行目标程序前先执行的程序。
	--post <cmd>：执行目标程序后再执行的程序。

 (3) 使用例子
    执行10次程序，给出标准偏差与期望的比值：
        # perf stat -r 10 ls > /dev/null
    显示更详细的信息：
        # perf stat -v ls > /dev/null
    只显示任务执行时间，不显示性能计数器：
        # perf stat -n ls > /dev/null
    单独给出每个CPU上的信息：
        # perf stat -a -A ls > /dev/null
    ls命令执行了多少次系统调用：
        # perf stat -e syscalls:sys_enter ls 

### 3.4 perf Top

	./perf top -e cpu_clock

使用 perf stat 的时候，往往您已经有一个调优的目标。比如我刚才写的那个无聊程序 t1。也有些时候，您只是发现系统性能无端下降，并不清楚究竟哪个进程成为了贪吃的 hog。此时需要一个类似 top 的命令，列出所有值得怀疑的进程，从中找到需要进一步审查的家伙。类似法制节目中办案民警常常做的那样，通过查看监控录像从茫茫人海中找到行为古怪的那些人，而不是到大街上抓住每一个人来审问。Perf top 用于实时显示当前系统的性能统计信息。该命令主要用来观察整个系统当前的状态，比如可以通过查看该命令的输出来查看当前系统最耗时的内核函数或某个用户进程。     Perf 在采样精度上定义了4个级别：

a. 无精度保证  
b. 采样指令与触发性能事件的 指令之间的偏差为常数(:p)  
c. 需要尽量保证采样指令与触发性能事件的指令之间的偏差为0(:pp)  
d. 保证采样指令与触发性能事件的指令之间的偏差必须为0(:ppp)  
      
	perf top -e cycles:pp

让我们再设计一个例子来演示吧。不知道您怎么想，反正我觉得做一件有益的事情很难，但做点儿坏事儿却非常容易。我很快就想到了如代码清单 2 所示的一个程序：

清单 2. 一个死循环
 while (1) i++;
我叫他 t2。启动 t2，然后用 perf top 来观察：
下面是 perf top 的可能输出：

	 PerfTop: 705 irqs/sec kernel:60.4% [1000Hz cycles] 
	 -------------------------------------------------- 
	 sampl pcnt function DSO 
	 1503.00 49.2% t2 
	 72.00 2.2% pthread_mutex_lock /lib/libpthread-2.12.so 
	 68.00 2.1% delay_tsc [kernel.kallsyms] 
	 55.00 1.7% aes_dec_blk [aes_i586] 
	 55.00 1.7% drm_clflush_pages [drm] 
	 52.00 1.6% system_call [kernel.kallsyms] 
	 49.00 1.5% __memcpy_ssse3 /lib/libc-2.12.so 
	 48.00 1.4% __strstr_ia32 /lib/libc-2.12.so 
	 46.00 1.4% unix_poll [kernel.kallsyms] 
	 42.00 1.3% __ieee754_pow /lib/libm-2.12.so 
	 41.00 1.2% do_select [kernel.kallsyms] 
	 40.00 1.2% pixman_rasterize_edges libpixman-1.so.0.18.0 
	 37.00 1.1% _raw_spin_lock_irqsave [kernel.kallsyms] 
	 36.00 1.1% _int_malloc /lib/libc-2.12.so 
 
      很容易便发现 t2 是需要关注的可疑程序。不过其作案手法太简单：肆无忌惮地浪费着 CPU。所以我们不用再做什么其他的事情便可以找到问题所在。但现实生活中，影响性能的程序一般都不会如此愚蠢，所以我们往往还需要使用其他的 perf 工具进一步分析。通过添加 -e 选项，您可以列出造成其他事件的 TopN 个进程 / 函数。比如 -e cache-miss，用来看看谁造成的 cache miss 最多。

(1) 输出格式

    第一列：符号引发的性能事件的比例，默认指占用的cpu周期比例。
    第二列：符号所在的DSO(Dynamic Shared Object)，可以是应用程序、内核、动态链接库、模块。
    第三列：DSO的类型。[.]表示此符号属于用户态的ELF文件，包括可执行文件与动态链接库)。[k]表述此符号属于内核或模块。
    第四列：符号名。有些符号不能解析为函数名，只能用地址表示。

(2) 常用交互命令

    h：显示帮助
    UP/DOWN/PGUP/PGDN/SPACE：上下和翻页。
    a：annotate current symbol，注解当前符号。能够给出汇编语言的注解，给出各条指令的采样率。
    d：过滤掉所有不属于此DSO的符号。非常方便查看同一类别的符号。
    t：过滤所有不属于当前符号所属线程的符号。
    右方向键也是热键，它可以打开perf top的功能菜单。菜单上列出的各项功能分别对应上述各个热键的功能。
    P：将当前信息保存到perf.hist.N中。

(3) 常用命令行参数

    -e <event>：指明要分析的性能事件。
    -c <count>：用于指定性能计数器的采样周期。默认情况下，每秒钟采样4000次。
    -p <pid>：Profile events on existing Process ID (comma sperated list). 仅分析目标进程及其创建的线程。
    -t <tid>：用于指定带分析线程的 tid。指定tid后，perf top仅分析目标线程，不包括此线程创建的其它的线程。
    -k <path>：Path to vmlinux. Required for annotation functionality. 带符号表的内核映像所在的路径。
        与GDB类似，perf只有在DSO存在符号表的情况下才能解析出IP对应的具体符号。Perf通常采用以下顺序加载内核符号：
        -> /proc/kallsyms
        -> 用户通过’k'参数指定的路径。
        -> 当前路径下的“vmlinux"文件。
        -> /boot/vmlinux
        -> /boot/vmlinux-$(uts.release)
        -> /lib/modules/$(uts.release)/build/vmlinux
        -> /usr/lib/debug/lib/modules/$(uts.release)/build/vmlinx
    -K：不显示属于内核或模块的符号,对于只想分析应用程序的用户而言，使用此参数后，界面清爽很多。
    -U：不显示属于用户态程序的符号，即类型为[.]的符号。
    -f <n>：此参数主要用于符号过滤。指定参数后，界面上将仅显示采样数大于<n>的符号。
    -d <n>：界面的刷新周期，默认为2s，因为perf top默认每2s从mmap的内存区域读取一次性能数据。
    -a ：采集系统中所有CPU产生的性能事件，这也是默认情况。
    -m：指定perf开辟的mmap页面的数量。mmap缓存主要用于用户空间与内核空间的数据通信。perf在内核中的驱动将采集到的性能数据存入ring buffer，用户空间的分析程序则通过mmap机制从ring buffer中读取数据，默认情况下mmap的页面数量为128。当内核生成性能数据的速度过快时，就可能因为缓冲区满而导致数据丢失。
    -C or --cpu：指定待分析CPU列表。如系统中有4个CPU，如果仅需采集CPU0与CPU3的数据，命令：perf top -C 0,3
    -r <n>：指定分析程序的实时优先级。如上文所述，如果perf分析程序读取数据的速度长期小于内核生成数据的速度时，就可能导致采样数据的大量丢失，影响分析精度。在负载过高时，分析程序可能会因为调度延迟过高而不能及时读取数据。因此，在高负载系统中可以通过参数‘-r'将分析程序设置为实时进程，并为其设定较高的优先级。Linux中实时优先级的范围是[0,99]，其中优先级0最高。不要与范围是[-20,19]的nice值搞混。
    -i ：子进程将自动继承父进程的性能事件。从而使得perf能够采集到动态创建的进程的性能数据。但是，当采用'-p'参数仅分析特定进程的性能数据时，继承机制会被禁用。这数要是出于性能的考虑。
    --sym-annotate <symbol name> 指定待解析的符号名
    -z ：更新界面的数据后，清除历史信息。
    -F <n>：指定采样频率，此参数与’c'参数指定一个即可。当两个参数同时指定时，perf仅适用'-c'指定的值作为采样周期。
    -E <n>：指定界面上显示的符号数。如果用户仅希望查看 top <n>个符号，可以通过此参数实现。
    --tui：适用tui界面。tui为perf top的默认界面。如果用户打开 perf top后，出现的不是 tui界面，请检查系统中是否已安装 newt包。
    --stdio：使用TTY界面。当系统中未安装 newt软件包时，此界面为默认界面。
    -G：得到函数的调用关系图。
    perf top -G [fractal]，路径概率为相对值，加起来为100%，调用顺序为从下往上。
    perf top -G graph，路径概率为绝对值，加起来为该函数的热度。
    -v： 显示冗余信息，如符号地址、符号类型（全局、局部、用户、内核等）。
    -s <key1,key2>：指定界面显示的信息，以及这些信息的排序。perf提供的备选信息有：perf top -s comm,pid,dso,parent,symbol
        Comm： 触发事件的进程号
        PID：触发事件的进程号
        DSO：符号所属的DSO的名称
        Symbol：符号名
        Parent：调用路径的入口
     -n ：显示每个符号对应的采样数量   
     --show-total-period：在界面上显示符号对应的性能事件总数。如第二节所述，性能事件计数器在溢出时才会触发一次采样。两次采样之间的计数值即为这段时间内发生的事件总数，perf将其称为周期。
    -dsos <dso_name[,dso_name...]：仅显示dso名为dso_name的符号。可以同时指定多个dso，各个dso名字之间通过逗号隔开。
    --comms <comm[,comm...]>：仅显示属于进程 comm的符号。
    --symbols <symbol[,symbol...]>：仅显示指定的符号
    -M：显示符号注解时，可以通过此参数指定汇编语言的风格

 (4) 使用例子

    # perf top // 默认配置
    # perf top -G // 得到调用关系图
    # perf top -e cycles // 指定性能事件
    # perf top -p 23015,32476 // 查看这两个进程的cpu cycles使用情况
    # perf top -s comm,pid,symbol // 显示调用symbol的进程名和进程号
    # perf top --comms nginx,top // 仅显示属于指定进程的符号
    # perf top --symbols kfree // 仅显示指定的符号

### 3.5 使用 perf record/report ###

使用 top 和 stat 之后，您可能已经大致有数了。要进一步分析，便需要一些粒度更细的信息。比如说您已经断定目标程序计算量较大，也许是因为有些代码写的不够精简。那么面对长长的代码文件，究竟哪几行代码需要进一步修改呢？这便需要使用 perf record 记录单个函数级别的统计信息，并使用 perf report 来显示统计结果。您的调优应该将注意力集中到百分比高的热点代码片段上，假如一段代码只占用整个程序运行时间的 0.1%，即使您将其优化到仅剩一条机器指令，恐怕也只能将整体的程序性能提高 0.1%。俗话说，好钢用在刀刃上，不必我多说了。

仍以 t1 为例。
 
	perf record –e cpu-clock ./t1 
	perf record -r0 -F100000 -g ./t1
	perf report

不出所料，hot spot 是 longa( ) 函数。
但，代码是非常复杂难说的，t1 程序中的 foo1() 也是一个潜在的调优对象，为什么要调用 100 次那个无聊的 longa() 函数呢？但我们在上图中无法发现 foo1 和 foo2，更无法了解他们的区别了。
我曾发现自己写的一个程序居然有近一半的时间花费在 string 类的几个方法上，string 是 C++ 标准，我绝不可能写出比 STL 更好的代码了。因此我只有找到自己程序中过多使用 string 的地方。因此我很需要按照调用关系进行显示的统计信息。
使用 perf 的 -g 选项便可以得到需要的信息：

	perf record –e cpu-clock –g ./t1 
	perf report
	perf record -F count来指定采样频率

通过对 calling graph 的分析，能很方便地看到 91% 的时间都花费在 foo1() 函数中，因为它调用了 100 次 longa() 函数，因此假如 longa() 是个无法优化的函数，那么程序员就应该考虑优化 foo1，减少对 longa() 的调用次数。收集采样信息，并将其记录在数据文件中。随后可以通过其它工具(perf-report)对数据文件进行分析，结果类似于perf-top的。运行一个命令去记录它的配置到 perf.data，不显示任何东西，这个文件后面可以使用 perf report来查看。

(1) 常用参数

	perf record
	    -e：Select the PMU event.
	    -a：System-wide collection from all CPUs.
	    -p：Record events on existing process ID (comma separated list).
	    -A：Append to the output file to do incremental profiling.
	     -f：Overwrite existing data file.
	    -o：Output file name.
	    -g：Do call-graph (stack chain/backtrace) recording.
	    -C：Collect samples only on the list of CPUs provided.
	perf report
	    -i：Input file name. (default: perf.data)

(2) 使用例子

	perf record
	    记录nginx进程的性能数据：
	        # perf record -p `pgrep -d ',' nginx`
	    记录执行ls时的性能数据：
	        # perf record ls -g
	    记录执行ls时的系统调用，可以知道哪些系统调用最频繁：
	        # perf record -e syscalls:sys_enter ls
	perf report 
	    # perf report -i perf.data.2

### 3.6 使用 PMU 的例子 ###
例子 t1 和 t2 都较简单。所谓魔高一尺，道才能高一丈。要想演示 perf 更加强大的能力，我也必须想出一个高明的影响性能的例子，我自己想不出，只好借助于他人。下面这个例子 t3 参考了文章“Branch and Loop Reorganization to Prevent Mispredicts”[6]，该例子考察程序对奔腾处理器分支预测的利用率，如前所述，分支预测能够显著提高处理器的性能，而分支预测失败则显著降低处理器的性能。首先给出一个存在 BTB 失效的例子：
清单 3. 存在 BTB 失效的例子程序

	 //test.c 
	 #include <stdio.h> 
	 #include <stdlib.h> 
	
	 void foo() 
	 { 
	  int i,j; 
	  for(i=0; i< 10; i++) 
	  j+=2; 
	 } 
	 int main(void) 
	 { 
	  int i; 
	  for(i = 0; i< 100000000; i++) 
	  foo(); 
	  return 0; 
	 }

用 gcc 编译生成测试程序 t3:
 gcc – o t3 – O0 test.c
用 perf stat 考察分支预测的使用情况：
	 [lm@ovispoly perf]$ ./perf stat ./t3 
	
	  Performance counter stats for './t3': 
	
	 6240.758394 task-clock-msecs # 0.995 CPUs 
	 126 context-switches # 0.000 M/sec 
	 12 CPU-migrations # 0.000 M/sec 
	 80 page-faults # 0.000 M/sec 
	 17683221 cycles # 2.834 M/sec (scaled from 99.78%) 
	 10218147 instructions # 0.578 IPC (scaled from 99.83%) 
	 2491317951 branches # 399.201 M/sec (scaled from 99.88%) 
	 636140932 branch-misses # 25.534 % (scaled from 99.63%) 
	 126383570 cache-references # 20.251 M/sec (scaled from 99.68%) 
	 942937348 cache-misses # 151.093 M/sec (scaled from 99.58%) 
	
	  6.271917679 seconds time elapsed
可以看到 branche-misses 的情况比较严重，25% 左右。我测试使用的机器的处理器为 Pentium4，其 BTB 的大小为 16。而 test.c 中的循环迭代为 20 次，BTB 溢出，所以处理器的分支预测将不准确。
对于上面这句话我将简要说明一下，但关于 BTB 的细节，请阅读参考文献 [6]。
for 循环编译成为 IA 汇编后如下：
清单 4. 循环的汇编

	 // C code 
	 for ( i=0; i < 20; i++ ) 
	 { … } 
	
	 //Assembly code; 
	 mov    esi, data 
	 mov    ecx, 0 
	 ForLoop: 
	 cmp    ecx, 20 
	 jge    
	 EndForLoop 
	…
	 add    ecx, 1 
	 jmp    ForLoop 
	 EndForLoop:

可以看到，每次循环迭代中都有一个分支语句 jge，因此在运行过程中将有 20 次分支判断。每次分支判断都将写入 BTB，但 BTB 是一个 ring buffer，16 个 slot 写满后便开始覆盖。假如迭代次数正好为 16，或者小于 16，则完整的循环将全部写入 BTB，比如循环迭代次数为 4 次，则 BTB 应该如下图所示：
图 4. BTB buffer

这个 buffer 完全精确地描述了整个循环迭代的分支判定情况，因此下次运行同一个循环时，处理器便可以做出完全正确的预测。但假如迭代次数为 20，则该 BTB 随着时间推移而不能完全准确地描述该循环的分支预测执行情况，处理器将做出错误的判断。
我们将测试程序进行少许的修改，将迭代次数从 20 减少到 10，为了让逻辑不变，j++ 变成了 j+=2；
清单 5. 没有 BTB 失效的代码

	 #include <stdio.h> 
	 #include <stdlib.h> 
	
	 void foo() 
	 { 
	  int i,j; 
	  for(i=0; i< 10; i++) 
	  j+=2; 
	 } 
	 int main(void) 
	 { 
	  int i; 
	  for(i = 0; i< 100000000; i++) 
	  foo(); 
	  return 0; 
	 }

此时再次用 perf stat 采样得到如下结果：

	 [lm@ovispoly perf]$ ./perf stat ./t3 
	
	  Performance counter stats for './t3: 
	
	 2784.004851 task-clock-msecs # 0.927 CPUs 
	 90 context-switches # 0.000 M/sec 
	 8 CPU-migrations # 0.000 M/sec 
	 81 page-faults # 0.000 M/sec 
	 33632545 cycles # 12.081 M/sec (scaled from 99.63%) 
	 42996 instructions # 0.001 IPC (scaled from 99.71%) 
	 1474321780 branches # 529.569 M/sec (scaled from 99.78%) 
	 49733 branch-misses # 0.003 % (scaled from 99.35%) 
	 7073107 cache-references # 2.541 M/sec (scaled from 99.42%) 
	 47958540 cache-misses # 17.226 M/sec (scaled from 99.33%) 
	
	  3.002673524 seconds time elapsed

Branch-misses 减少了。
本例只是为了演示 perf 对 PMU 的使用，本身并无意义，关于充分利用 processor 进行调优可以参考 Intel 公司出品的调优手册，其他的处理器可能有不同的方法，还希望读者明鉴

### 3.7 小结 ###
以上介绍的这些 perf 用法主要着眼点在于对于应用程序的性能统计分析，本文的第二部分将继续讲述 perf 的一些特殊用法，并偏重于内核本身的性能统计分析。调优是需要综合知识的工作，要不断地修炼自己。Perf 虽然是一把宝剑，但宝剑配英雄，只有武功高强的大侠才能随心所欲地使用它。以我的功力，也只能道听途说地讲述一些关于宝刀的事情。但若本文能引起您对宝刀的兴趣，那么也算是有一点儿作用了。

## 4. 内核性能分析 ##
### 4.1 本文内容简介 ###

之前介绍了 perf 最常见的一些用法，关注于 Linux 系统上应用程序的调优。现在让我们把目光转移到内核以及其他 perf 命令上面来。在内核方面，人们的兴趣五花八门，有些内核开发人员热衷于寻找整个内核中的热点代码；另一些则只关注某一个主题，比如 slab 分配器，对于其余部分则不感兴趣。对这些人而言，perf 的一些奇怪用法更受欢迎。当然，诸如 perf top，perf stat, perf record 等也是内核调优的基本手段，但用法和 part1 所描述的一样，无需重述。此外虽然内核事件对应用程序开发人员而言有些陌 生，但一旦了解，对应用程序的调优也很有帮助。我曾经参与开发过一个数据库应用程序，其效率很低。通过常规的热点查询，IO 统计等方法，我们找到了一些可以优化的地方，以至于将程序的效率提高了几倍。可惜对于拥有海量数据的用户，其运行时间依然无法达到要求。进一步调优需要更加详细的统计信息，可惜本人经验有限，实在是无计可施。从客户反馈来看，该应用的使用频率很低。作为一个程序员，为此我时常心情沮丧。假如有 perf，那么我想我可以用它来验证自己的一些猜测，比如是否太多的系统调用，或者系统中的进程切换太频繁 ? 针对这些怀疑使用 perf 都可以拿出有用的报告，或许能找到问题吧。这里我还要提醒读者注意，讲述 perf 的命令和语法容易，但说明什么时候使用这些命令，或者说明怎样解决实际问题则很困难。就好象说明电子琴上 88 个琴键的唱名很容易，但想说明如何弹奏动听的曲子则很难。在简述每个命令语法的同时，我试图通过一些示例来说明这些命令的使用场景，但这只能是一种微薄的努力。因此总体说来，本文只能充当那本随同电子琴一起发售的使用说明书。

### 4.2 使用 tracepoint ###
当 perf 根据 tick 时间点进行采样后，人们便能够得到内核代码中的 hot spot。那什么时候需要使用 tracepoint 来采样呢？我想人们使用 tracepoint 的基本需求是对内核的运行时行为的关心，如前所述，有些内核开发人员需要专注于特定的子系统，比如内存管理模块。这便需要统计相关内核函数的运行情况。另外，内核行为对应用程序性能的影响也是不容忽视的：
下面我用 ls 命令来演示 sys_enter 这个 tracepoint 的使用：
	 [root@ovispoly /]# perf stat -e raw_syscalls:sys_enter ls 
	 bin dbg etc  lib  media opt root  selinux sys usr 
	 boot dev home lost+found mnt proc sbin srv  tmp var 
	
	  Performance counter stats for 'ls': 
	
	 101 raw_syscalls:sys_enter 
	
	  0.003434730 seconds time elapsed 
	
	
	 [root@ovispoly /]# perf record -e raw_syscalls:sys_enter ls 
	
	 [root@ovispoly /]# perf report 
	 Failed to open .lib/ld-2.12.so, continuing without symbols 
	 # Samples: 70 
	 # 
	 # Overhead Command Shared Object Symbol 
	 # ........ ............... ............... ...... 
	 # 
	 97.14% ls ld-2.12.so [.] 0x0000000001629d 
	 2.86% ls [vdso] [.] 0x00000000421424 
	 # 
	 # (For a higher level overview, try: perf report --sort comm,dso) 
	 #
这个报告详细说明了在 ls 运行期间发生了多少次系统调用 ( 上例中有 101 次 )，多数系统调用都发生在哪些地方 (97% 都发生在 ld-2.12.so 中 )。有了这个报告，或许我能够发现更多可以调优的地方。比如函数 foo() 中发生了过多的系统调用，那么我就可以思考是否有办法减少其中有些不必要的系统调用。您可能会说 strace 也可以做同样事情啊，的确，统计系统调用这件事完全可以用 strace 完成，但 perf 还可以干些别的，您所需要的就是修改 -e 选项后的字符串。罗列 tracepoint 实在是不太地道，本文当然不会这么做。但学习每一个 tracepoint 是有意义的，类似背单词之于学习英语一样，是一项缓慢痛苦却不得不做的事情。

### 4.3 Perf probe ###
tracepoint 是静态检查点，意思是一旦它在哪里，便一直在那里了，您想让它移动一步也是不可能的。内核代码有多少行？我不知道，100 万行是至少的吧，但目前 tracepoint 有多少呢？我最大胆的想象是不超过 1000 个。所以能够动态地在想查看的地方插入动态监测点的意义是不言而喻的。Perf 并不是第一个提供这个功能的软件，systemTap 早就实现了。但假若您不选择 RedHat 的发行版的话，安装 systemTap 并不是件轻松愉快的事情。perf 是内核代码包的一部分，所以使用和维护都非常方便。

我使用的 Linux 版本为 2.6.33。因此您自己做实验时命令参数有可能不同。

	 [root@ovispoly perftest]# perf probe schedule:12 cpu 
	 Added new event: 
	 probe:schedule (on schedule+52 with cpu) 
	
	 You can now use it on all perf tools, such as: 
	
	   perf record -e probe:schedule -a sleep 1 
	
	 [root@ovispoly perftest]# perf record -e probe:schedule -a sleep 1 
	 Error, output file perf.data exists, use -A to append or -f to overwrite. 
	
	 [root@ovispoly perftest]# perf record -f -e probe:schedule -a sleep 1 
	 [ perf record: Woken up 1 times to write data ] 
	 [ perf record: Captured and wrote 0.270 MB perf.data (~11811 samples) ] 
	 [root@ovispoly perftest]# perf report 
	 # Samples: 40 
	 # 
	 # Overhead Command Shared Object Symbol 
	 # ........ ............... ................. ...... 
	 # 
	 57.50% init 0 [k] 0000000000000000 
	 30.00% firefox [vdso] [.] 0x0000000029c424 
	 5.00% sleep [vdso] [.] 0x00000000ca7424 
	 5.00% perf.2.6.33.3-8 [vdso] [.] 0x00000000ca7424 
	 2.50% ksoftirqd/0 [kernel] [k] 0000000000000000 
	 # 
	 # (For a higher level overview, try: perf report --sort comm,dso) 
	 #

上例利用 probe 命令在内核函数 schedule() 的第 12 行处加入了一个动态 probe 点，和 tracepoint 的功能一样，内核一旦运行到该 probe 点时，便会通知 perf。可以理解为动态增加了一个新的 tracepoint。
此后便可以用 record 命令的 -e 选项选择该 probe 点，最后用 perf report 查看报表。如何解读该报表便是见仁见智了，既然您在 shcedule() 的第 12 行加入了 probe 点，想必您知道自己为什么要统计它吧？
可以自定义探测点。
Define new dynamic tracepoints.
 使用例子
(1) Display which lines in schedule() can be probed

    # perf probe --line schedule
    前面有行号的可以探测，没有行号的就不行了。

(2) Add a probe on schedule() function 12th line.

    # perf probe -a schedule:12
    在schedule函数的12处增加一个探测点。

### 4.4 Perf sched ###

     调度器的好坏直接影响一个系统的整体运行效率。在这个领域，内核黑客们常会发生争执，一个重要原因是对于不同的调度器，每个人给出的评测报告都各不相同，甚至常常有相反的结论。因此一个权威的统一的评测工具将对结束这种争论有益。Perf sched 便是这种尝试。
	Perf sched 有五个子命令：perf sched {record | latency | map | replay | script}
	  perf sched record            # low-overhead recording of arbitrary workloads 
	  perf sched latency           # output per task latency metrics 
	  perf sched map               # show summary/map of context-switching 
	  perf sched trace             # output finegrained trace 
	  perf sched replay            # replay a captured workload using simlated threads
	      用户一般使用’ perf sched record ’收集调度相关的数据，然后就可以用’ perf sched latency ’查看诸如调度延迟等和调度器相关的统计数据。其他三个命令也同样读取 record 收集到的数据并从其他不同的角度来展示这些数据。下面一一进行演示。
	 perf sched record sleep 10     # record full system activity for 10 seconds 
	 perf sched latency --sort max  # report latencies sorted by max 
	
	 -------------------------------------------------------------------------------------
	  Task               |   Runtime ms  | Switches | Average delay ms | Maximum delay ms | 
	 -------------------------------------------------------------------------------------
	  :14086:14086        |      0.095 ms |        2 | avg:    3.445 ms | max:    6.891 ms | 
	  gnome-session:13792   |   31.713 ms |      102 | avg:    0.160 ms | max:    5.992 ms | 
	  metacity:14038      |     49.220 ms |      637 | avg:    0.066 ms | max:    5.942 ms | 
	  gconfd-2:13971     | 48.587 ms |      777 | avg:    0.047 ms | max:    5.793 ms | 
	  gnome-power-man:14050 |  140.601 ms | 434 | avg:  0.097 ms | max:    5.367 ms | 
	  python:14049        |  114.694 ms |      125 | avg:    0.120 ms | max:    5.343 ms | 
	  kblockd/1:236       |   3.458 ms |      498 | avg:    0.179 ms | max:    5.271 ms | 
	  Xorg:3122         |   1073.107 ms |     2920 | avg:    0.030 ms | max:    5.265 ms | 
	  dbus-daemon:2063   |   64.593 ms |      665 | avg:    0.103 ms | max:    4.730 ms | 
	  :14040:14040       |   30.786 ms |      255 | avg:    0.095 ms | max:    4.155 ms | 
	  events/1:8         |    0.105 ms |       13 | avg:    0.598 ms | max:    3.775 ms | 
	  console-kit-dae:2080  | 14.867 ms |   152 | avg:    0.142 ms | max:    3.760 ms | 
	  gnome-settings-:14023 |  572.653 ms |  979 | avg:    0.056 ms | max:    3.627 ms | 
	 ... 
	 -----------------------------------------------------------------------------------
	  TOTAL:                |   3144.817 ms |    11654 | 
	 --------------------------------------------------- 

上面的例子展示了一个 Gnome 启动时的统计信息。
各个 column 的含义如下：
 Task: 进程的名字和 pid 
 Runtime: 实际运行时间
 Switches: 进程切换的次数
 Average delay: 平均的调度延迟
 Maximum delay: 最大延迟
 
这里最值得人们关注的是 Maximum delay，一般从这里可以看到对交互性影响最大的特性：调度延迟，如果调度延迟比较大，那么用户就会感受到视频或者音频断断续续的。其他的三个子命令提供了不同的视图，一般是由调度器的开发人员或者对调度器内部实现感兴趣的人们所使用。

首先是 map:

	  $ perf sched map 
	  ... 
	
	   N1  O1  .   .   .   S1  .   .   .   B0  .  *I0  C1  .   M1  .    23002.773423 secs 
	   N1  O1  .  *Q0  .   S1  .   .   .   B0  .   I0  C1  .   M1  .    23002.773423 secs 
	   N1  O1  .   Q0  .   S1  .   .   .   B0  .  *R1  C1  .   M1  .    23002.773485 secs 
	   N1  O1  .   Q0  .   S1  .  *S0  .   B0  .   R1  C1  .   M1  .    23002.773478 secs 
	  *L0  O1  .   Q0  .   S1  .   S0  .   B0  .   R1  C1  .   M1  .    23002.773523 secs 
	   L0  O1  .  *.   .   S1  .   S0  .   B0  .   R1  C1  .   M1  .    23002.773531 secs 
	   L0  O1  .   .   .   S1  .   S0  .   B0  .   R1  C1 *T1  M1  .    23002.773547 secs 
	                       T1 => irqbalance:2089 
	   L0  O1  .   .   .   S1  .   S0  .  *P0  .   R1  C1  T1  M1  .    23002.773549 secs 
	  *N1  O1  .   .   .   S1  .   S0  .   P0  .   R1  C1  T1  M1  .    23002.773566 secs 
	   N1  O1  .   .   .  *J0  .   S0  .   P0  .   R1  C1  T1  M1  .    23002.773571 secs 
	   N1  O1  .   .   .   J0  .   S0 *B0  P0  .   R1  C1  T1  M1  .    23002.773592 secs 
	   N1  O1  .   .   .   J0  .  *U0  B0  P0  .   R1  C1  T1  M1  .    23002.773582 secs 
	   N1  O1  .   .   .  *S1  .   U0  B0  P0  .   R1  C1  T1  M1  .    23002.773604 secs

星号表示调度事件发生所在的 CPU。
点号表示该 CPU 正在 IDLE。
Map 的好处在于提供了一个的总的视图，将成百上千的调度事件进行总结，显示了系统任务在 CPU 之间的分布，假如有不好的调度迁移，比如一个任务没有被及时迁移到 idle 的 CPU 却被迁移到其他忙碌的 CPU，类似这种调度器的问题可以从 map 的报告中一眼看出来。
如果说 map 提供了高度概括的总体的报告，那么 trace 就提供了最详细，最底层的细节报告。

	  pipe-test-100k-13520 [001]  1254.354513808: sched_stat_wait: 
	 task: pipe-test-100k:13521 wait: 5362 [ns] 
	  pipe-test-100k-13520 [001]  1254.354514876: sched_switch: 
	 task pipe-test-100k:13520 [120] (S) ==> pipe-test-100k:13521 [120] 
	          :13521-13521 [001]  1254.354517927: sched_stat_runtime: 
	 task: pipe-test-100k:13521 runtime: 5092 [ns], vruntime: 133967391150 [ns] 
	          :13521-13521 [001]  1254.354518984: sched_stat_sleep: 
	 task: pipe-test-100k:13520 sleep: 5092 [ns] 
	          :13521-13521 [001]  1254.354520011: sched_wakeup: 
	 task pipe-test-100k:13520 [120] success=1 [001]

要理解以上的信息，必须对调度器的源代码有一定了解，对一般用户而言，理解他们十分不易。幸好这些信息一般也只有编写调度器的人感兴趣。。。
Perf replay 这个工具更是专门为调度器开发人员所设计，它试图重放 perf.data 文件中所记录的调度场景。很多情况下，一般用户假如发现调度器的奇怪行为，他们也无法准确说明发生该情形的场景，或者一些测试场景不容易再次重现，或者仅 仅是出于“偷懒”的目的，使用 perf replay，perf 将模拟 perf.data 中的场景，无需开发人员花费很多的时间去重现过去，这尤其利于调试过程，因为需要一而再，再而三地重复新的修改是否能改善原始的调度场景所发现的问题。
下面是 replay 执行的示例：

	 $ perf sched replay 
	 run measurement overhead: 3771 nsecs 
	 sleep measurement overhead: 66617 nsecs 
	 the run test took 999708 nsecs 
	 the sleep test took 1097207 nsecs 
	 nr_run_events:        200221 
	 nr_sleep_events:      200235 
	 nr_wakeup_events:     100130 
	 task      0 (                perf:     13519), nr_events: 148 
	 task      1 (                perf:     13520), nr_events: 200037 
	 task      2 (      pipe-test-100k:     13521), nr_events: 300090 
	 task      3 (         ksoftirqd/0:         4), nr_events: 8 
	 task      4 (             swapper:         0), nr_events: 170 
	 task      5 (     gnome-power-man:      3192), nr_events: 3 
	 task      6 (     gdm-simple-gree:      3234), nr_events: 3 
	 task      7 (                Xorg:      3122), nr_events: 5 
	 task      8 (     hald-addon-stor:      2234), nr_events: 27 
	 task      9 (               ata/0:       321), nr_events: 29 
	 task     10 (           scsi_eh_4:       704), nr_events: 37 
	 task     11 (            events/1:         8), nr_events: 3 
	 task     12 (            events/0:         7), nr_events: 6 
	 task     13 (           flush-8:0:      6980), nr_events: 20 
	 ------------------------------------------------------------ 
	 #1  : 2038.157, ravg: 2038.16, cpu: 0.09 / 0.09 
	 #2  : 2042.153, ravg: 2038.56, cpu: 0.11 / 0.09 
 
 
### 4.5 Perf bench ###

除了调度器之外，很多时候人们都需要衡量自己的工作对系统性能的影响。benchmark 是衡量性能的标准方法，对于同一个目标，如果能够有一个大家都承认的 benchmark，将非常有助于”提高内核性能”这项工作。目前，就我所知，perf bench 提供了 3 个 benchmark:
#### 1. Sched message ####

[lm@ovispoly ~]$ perf bench sched messaging 

sched message 是从经典的测试程序 hackbench 移植而来，用来衡量调度器的性能，overhead 以及可扩展性。该 benchmark 启动 N 个 reader/sender 进程或线程对，通过 IPC(socket 或者 pipe) 进行并发的读写。一般人们将 N 不断加大来衡量调度器的可扩展性。Sched message 的用法及用途和 hackbench 一样。

#### 2. Sched Pipe ####
[lm@ovispoly ~]$ perf bench sched pipe

Sched pipe 从 Ingo Molnar 的 pipe-test-1m.c 移植而来。当初 Ingo 的原始程序是为了测试不同的调度器的性能和公平性的。其工作原理很简单，两个进程互相通过 pipe 拼命地发 1000000 个整数，进程 A 发给 B，同时 B 发给 A。因为 A 和 B 互相依赖，因此假如调度器不公平，对 A 比 B 好，那么 A 和 B 整体所需要的时间就会更长。

#### 3. Mem memcpy ####
[lm@ovispoly ~]$ perf bench mem memcpy

这个是 perf bench 的作者 Hitoshi Mitake 自己写的一个执行 memcpy 的 benchmark。该测试衡量一个拷贝 1M 数据的 memcpy() 函数所花费的时间。我尚不明白该 benchmark 的使用场景。。。或许是一个例子，告诉人们如何利用 perf bench 框架开发更多的 benchmark 吧。这三个 benchmark 给我们展示了一个可能的未来：不同语言，不同肤色，来自不同背景的人们将来会采用同样的 benchmark，只要有一份 Linux 内核代码即可。

### 4.6 Perf lock ###
锁是内核同步的方法，一旦加了锁，其他准备加锁的内核执行路径就必须等待，降低了并行。因此对于锁进行专门分析应该是调优的一项重要工作。目 前 perf lock 还处于比较初级的阶段，我想在后续的内核版本中，还应该会有较大的变化，因此当您开始使用 perf lock 时，恐怕已经和本文这里描述的有所不同了。不过我又一次想说的是，命令语法和输出并不是最重要的，重要的是了解什么时候我们需要用这个工具，以及它能帮我 们解决怎样的问题。

(1) 常用选项
-i <file>：输入文件
-k <value>：sorting key，默认为acquired，还可以按contended、wait_total、wait_max和wait_min来排序。

(2) 使用例子
	# perf lock record ls // 记录
	# perf lock report // 报告

 (3) 输出格式

	                Name   acquired  contended total wait (ns)   max wait (ns)   min wait (ns) 
	
	 &mm->page_table_...        382          0               0               0               0 
	 &mm->page_table_...         72          0               0               0               0 
	           &fs->lock         64          0               0               0               0 
	         dcache_lock         62          0               0               0               0 
	       vfsmount_lock         43          0               0               0               0 
	 &newf->file_lock...         41          0               0               0               0

	 Name：内核锁的名字。
	aquired：该锁被直接获得的次数，因为没有其它内核路径占用该锁，此时不用等待。
	contended：该锁等待后获得的次数，此时被其它内核路径占用，需要等待。
	total wait：为了获得该锁，总共的等待时间。
	max wait：为了获得该锁，最大的等待时间。
	min wait：为了获得该锁，最小的等待时间。
	最后还有一个Summary：
	=== output for debug===
	
	bad: 10, total: 246
	bad rate: 4.065041 %
	histogram of events caused bad sequence
	    acquire: 0
	   acquired: 0
	  contended: 0
	    release: 10

### 4.7 perf Kmem ###
Tool to trace/measure kernel memory(slab) properties.
perf kmem {record | stat} [<options>]
Perf Kmem 专门收集内核 slab 分配器的相关事件。比如内存分配，释放等。可以用来研究程序在哪里分配了大量内存，或者在什么地方产生碎片之类的和内存管理相关的问题。Perf kmem 和 perf lock 实际上都是 perf tracepoint 的特例，您也完全可以用 Perf record – e kmem:* 或者 perf record – e lock:* 来完成同样的功能。但重要的是，这些工具在内部对原始数据进行了汇总和分析，因而能够产生信息更加明确更加有用的统计报表。
perf kmem 的输出结果如下：

	 [root@ovispoly perf]# ./perf kmem --alloc -l 10 --caller stat 
	 --------------------------------------------------------------------------- 
	 Callsite       | Total_alloc/Per | Total_req/Per | Hit | Ping-pong| Frag 
	 --------------------------------------------------------------------------- 
	 perf_mmap+1a8 | 1024/1024 | 572/572|1 | 0 | 44.141% 
	 seq_open+15| 12384/96 | 8772/68 |129 | 0 | 29.167% 
	 do_maps_open+0| 1008/16 | 756/12 |63 | 0 | 25.000% 
	 ...| ... | ...| ... | ... | ... 
	 __split_vma+50| 88/88 | 88/88 | 1 | 0 | 0.000% 
	 --------------------------------------------------------------------------- 
	  Alloc Ptr | Total_alloc/Per | Total_req/Per | Hit |Ping-pong| Frag 
	 --------------------------------------------------------------------------- 
	 0xd15d4600|64/64 | 33/33  1 |  0 | 48.438% 
	 0xc461e000|1024/1024 | 572/572 |1 | 0 | 44.141% 
	 0xd15d44c0| 64/64 | 38/38 |1 | 0 | 40.625% 
	 ... | ... | ... | ... | ... | ... 
	 --------------------------------------------------------------------------- 
	
	 SUMMARY 
	 ======= 
	 Total bytes requested: 10487021 
	 Total bytes allocated: 10730448 
	 Total bytes wasted on internal fragmentation: 243427 
	 Internal fragmentation: 2.268563% 
	 Cross CPU allocations: 0/246458

该报告有三个部分：根据 Callsite 显示的部分，所谓 Callsite 即内核代码中调用 kmalloc 和 kfree 的地方。比如上图中的函数 perf_mmap，Hit 栏为 1，表示该函数在 record 期间一共调用了 kmalloc 一次，假如如第三行所示数字为 653，则表示函数 sock_alloc_send_pskb 共有 653 次调用 kmalloc 分配内存。对于第一行 Total_alloc/Per 显示为 1024/1024，第一个值 1024 表示函数 perf_mmap 总共分配的内存大小，Per 表示平均值。

比较有趣的两个参数是 Ping-pong 和 Frag。Frag 比较容易理解，即内部碎片。虽然相对于 Buddy System，Slab 正是要解决内部碎片问题，但 slab 依然存在内部碎片，比如一个 cache 的大小为 1024，但需要分配的数据结构大小为 1022，那么有 2 个字节成为碎片。Frag 即碎片的比例。Ping-pong 是一种现象，在多 CPU 系统中，多个 CPU 共享的内存会出现”乒乓现象”。一个 CPU 分配内存，其他 CPU 可能访问该内存对象，也可能最终由另外一个 CPU 释放该内存对象。而在多 CPU 系统中，L1 cache 是 per CPU 的，CPU2 修改了内存，那么其他的 CPU 的 cache 都必须更新，这对于性能是一个损失。Perf kmem 在 kfree 事件中判断 CPU 号，如果和 kmalloc 时的不同，则视为一次 ping-pong，理想的情况下 ping-pone 越小越好。Ibm developerworks 上有一篇讲述 oprofile 的文章，其中关于 cache 的调优可以作为很好的参考资料。后面则有根据被调用地点的显示方式的部分。最后一个部分是汇总数据，显示总的分配的内存和碎片情况，Cross CPU allocation 即 ping-pong 的汇总。

(1) 常用选项
    --i <file>：输入文件
    --caller：show per-callsite statistics，显示内核中调用kmalloc和kfree的地方。
    --alloc：show per-allocation statistics，显示分配的内存地址。
    -l <num>：print n lines only，只显示num行。
    -s <key[,key2...]>：sort the output (default: frag,hit,bytes)

(2) 使用例子
    # perf kmem record ls // 记录
    # perf kmem stat --caller --alloc -l 20 // 报告
 

### 4.8 Perf timechart ###
很多 perf 命令都是为调试单个程序或者单个目的而设计。有些时候，性能问题并非由单个原因所引起，需要从各个角度一一查看。为此，人们常需要综合利用各种工具，比如 top,vmstat,oprofile 或者 perf。这非常麻烦。此外，前面介绍的所有工具都是基于命令行的，报告不够直观。更令人气馁的是，一些报告中的参数令人费解。所以人们更愿意拥有一个“傻瓜式”的工具。以上种种就是 perf timechart 的梦想，其灵感来源于 bootchart。采用“简单”的图形“一目了然”地揭示问题所在。加 注了引号的原因是，perf timechart 虽然有了美观的图形输出，但对于新手，这个图形就好象高科技节目中播放的 DNA 图像一样，不明白那些坐在屏幕前的人是如何从密密麻麻的点和线中找到有用的信息的。但正如受过训练的科学家一样，经过一定的练习，相信您也一定能从下图中 找到您想要的。

人们说，只有黑白两色是一个人内心压抑的象征，Timechart 用不同的颜色代表不同的含义。上图的最上面一行是图例，告诉人们每种颜色所代表的含义。蓝色表示忙碌，红色表示 idle，灰色表示等待，等等。接下来是 per-cpu 信息，上图所示的系统中有两个处理器，可以看到在采样期间，两个处理器忙碌程度的概括。蓝色多的地方表示忙碌，因此上图告诉我们，CPU1 很忙，而 CPU2 很闲。再下面是 per-process 信息，每一个进程有一个 bar。上图中进程 bash 非常忙碌，而其他进程则大多数时间都在等待着什么。Perf 自己在开始的时候很忙，接下来便开始 wait 了。

### 4.9 使用 Script 增强 perf 的功能 ###
通常，面对看似复杂，实则较有规律的计算机输出，程序员们总是会用脚本来进行处理：比如给定一个文本文件，想从中找出有多少个数字 0125，人们不会打开文件然后用肉眼去一个一个地数，而是用 grep 命令来进行处理。

perf 的输出虽然是文本格式，但还是不太容易分析和阅读。往往也需要进一步处理，perl 和 python 是目前最强大的两种脚本语言。Tom Zanussi 将 perl 和 python 解析器嵌入到 perf 程序中，从而使得 perf 能够自动执行 perl 或者 python 脚本进一步进行处理，从而为 perf 提供了强大的扩展能力。因为任何人都可以编写新的脚本，对 perf 的原始输出数据进行所需要的进一步处理。这个特性所带来的好处很类似于 plug-in 之于 eclipse。
下面的命令可以查看系统中已经安装的脚本：

	 # perf trace -l 
	    List of available trace scripts: 
	      syscall-counts [comm]                system-wide syscall counts 
	      syscall-counts-by-pid [comm]         system-wide syscall counts, by pid 
	      failed-syscalls-by-pid [comm]        system-wide failed syscalls, by pid 

比如 failed-syscalls 脚本，执行的效果如下：
	 # perf trace record failed-syscalls 
	    ^C[ perf record: Woken up 11 times to write data ]                         
	    [ perf record: Captured and wrote 1.939 MB perf.data (~84709 samples) ]   
	
	 perf trace report failed-syscalls 
	    perf trace started with Perl script \ 
		 /root/libexec/perf-core/scripts/perl/failed-syscalls.pl 
	
	    failed syscalls, by comm: 
	
	    comm                    # errors 
	    --------------------  ---------- 
	    firefox                     1721 
	    claws-mail                   149 
	    konsole                       99 
	    X                             77 
	    emacs                         56 
	    [...] 
	
	    failed syscalls, by syscall: 
	
	    syscall                           # errors 
	    ------------------------------  ---------- 
	    sys_read                              2042 
	    sys_futex                              130 
	    sys_mmap_pgoff                          71 
	    sys_access                              33 
	    sys_stat64                               5 
	    sys_inotify_add_watch                    4 
	    [...]
该报表分别按进程和按系统调用显示失败的次数。非常简单明了，而如果通过普通的 perf record 加 perf report 命令，则需要自己手工或者编写脚本来统计这些数字。
我想重要的不仅是学习目前已经存在的这些脚本，而是理解如何利用 perf 的脚本功能开发新的功能。但如何写 perf 脚本超出了本文的范围，要想描述清楚估计需要一篇单独的文章。因此不再赘述。


## 5.perf guest ##

https://www.ibm.com/developerworks/community/blogs/IBMzOS/entry/20141104?lang=en

## 结束语 ##

从 2.6.31 开始，一晃居然也有几个年头了，期间每一个内核版本都会有新的 perf 特性。因此于我而言，阅读新的 changelog 并在其中发现 perf 的新功能已经成为一项乐趣，类似喜欢陈奕迅的人们期待他创作出新的专辑一般。本文写到这里可以暂时告一段落，还有一些命令没有介绍，而且或许就在此时此刻，新的功能已经加入 perf 家族了。所以当您读到这篇文章时，本文恐怕已经开始泛黄，然而我依旧感到高兴，因为我正在经历一个伟大时代，Linux 的黄金时代吧。

## 参考资料 ##

2.6.34 源代码 tools 目录下的文档。
Lwn 上的文章 Perfcounters added to the mainline以及 Scripting support for perf。
Ingo Molnar 写的关于 sched perf的教材。
Arjan van de Ven ’ s 关于 timechart 的 blog。
IBM Developerworks 网站上的文章 用 OProfile 彻底了解性能。
Intel 公司的 Jeff Andrews 写的 Branch and Loop Reorganization to Prevent Mispredicts。
在 developerWorks Linux 专区 寻找为 Linux 开发人员（包括 Linux 新手入门）准备的更多参考资料，查阅我们 最受欢迎的文章和教程。
在 developerWorks 上查阅所有 Linux 技巧 和 Linux 教程。
随时关注 developerWorks 技术活动和网络广播。

https://perf.wiki.kernel.org/index.php/Tutorial
https://perf.wiki.kernel.org/index.php/Main_Page，perf主页
http://www.docin.com/p-619608212.html，Linux 的系统级性能剖析工具-perf （一） - 淘宝内核组
http://www.docin.com/p-619619774.html，Linux 的系统级性能剖析工具-perf （二） - 淘宝内核组
http://www.ibm.com/developerworks/cn/linux/l-cn-perf1/，Perf -- Linux下的系统性能调优工具

