# 1. 调度器 #

![](/kvm_blog/files/kernel/sched_class.jpg)

核心调度器由周期性调度器和主调度器，其中周期性调度器在 scheduler_tick中实现。如果系统正在活动中，内核会按照频率HZ自动调用该函数; 主调度器在内核的许多地方，如果要将CPU分配给与当前活动进程不同的另一个进程，都会直接调用主调度器函数(schedule)

实时进程和普通的进程有一个根本的不同之处:如果系统中有一个实时进程且可运行，那么调度器总会选中它运行，除非有一个优先级更高的实时进程。现有的两种实时类:

- 循环进程(SCHED_RR)有时间片，其值在进程运行时会减少，就像是普通进程。在所有的时间段都到期后，则该值重置为初始值，而进程则置于队列的末尾。这确保了在有几个优先级相同的 SCHED_RR 进程的情况下，他们总是依次执行。
- 先进先出进程(SCHED_FIFO)没有时间片，在被调度器选择执行后，可以运行任意长时间。

# 2. 进程优先级 #

用top或者ps命令会输出PRI/PR、NI、%ni/%nice这三种指标值，这些到底是什么东西？先给出大概的解释如下：

- PRI ：进程优先权，代表这个进程可被执行的优先级，其值越小，优先级就越高，越早被执行
- NI ：进程Nice值，代表这个进程的优先值
- %nice ：改变过优先级的进程的占用CPU的百分比
 
PRI是比较好理解的，即进程的优先级，或者通俗点说就是程序被CPU执行的先后顺序，此值越小进程的优先级别越高。那NI呢？就是我们所要说的nice值了，其表示进程可被执行的优先级的修正数值。如前面所说，PRI值越小越快被执行，那么加入nice值后，将会使得PRI变为：PRI(new)=PRI(old)+nice。由此看出，PR是根据NICE排序的，规则是NICE越小PR越前（小，优先权更大），即其优先级会变高，则其越快被执行。如果NICE相同则进程uid是root的优先权更大。
 
在LINUX系统中，Nice值的范围从-20到+19（不同系统的值范围是不一样的），正值表示低优先级，负值表示高优先级，值为零则表示不会调整该进程的优先级。具有最高优先级的程序，其nice值最低，所以在LINUX系统中，值-20使得一项任务变得非常重要；与之相反，如果任务的nice为+19，则表示它是一个高尚的、无私的任务，允许所有其他任务比自己享有宝贵的CPU时间的更大使用份额，这也就是nice的名称的来意。
 
进程在创建时被赋予不同的优先级值，而如前面所说，nice的值是表示进程优先级值可被修正数据值，因此，每个进程都在其计划执行时被赋予一个nice值，这样系统就可以根据系统的资源以及具体进程的各类资源消耗情况，主动干预进程的优先级值。在通常情况下，子进程会继承父进程的nice值，比如在系统启动的过程中，init进程会被赋予0，其他所有进程继承了这个nice值（因为其他进程都是init的子进程）。
 
对nice值一个形象比喻，假设在一个CPU轮转中，有2个runnable的进程A和B，如果他们的nice值都为0，假设内核会给他们每人分配1k个cpu时间片。但是假设进程A的为0，但是B的值为-10，那么此时CPU可能分别给A和B分配1k和1.5k的时间片。故可以形象的理解为，nice的值影响了内核分配给进程的cpu时间片的多少，时间片越多的进程，其优先级越高，其优先级值（PRI）越低。%nice，就是改变过优先级的进程的占用CPU的百分比，如上例中就是0.5k/2.5k=1/5=20%。
 
由此可见，进程nice值和进程优先级不是一个概念，但是进程nice值会影响到进程的优先级变化。
 
进程的nice值是可以被修改的，修改命令分别是nice和renice。

- nice命令就是设置一个要执行command进程的nice值，其命令格式是 nice –n adjustment command command_option，如果这里不指定adjustment，则默认为10。
- renice命令就是设置一个已经在运行的进程的nice值，假设一运行进程本来nice值为0，renice为3后，则这个运行进程的nice值就为3了。
说明：如果用户设置的nice值超过了nice的边界值（LINUX为-20到+19），系统就取nice的边界值作为进程的nice值。

举例如下：
对非root用户，只能将其底下的进程的nice值变大而不能变小。若想变小，得要有相应的权限。

	[oracle@perf_dbc ~]$ nice
	0
	[oracle@perf_dbc ~]$ nice -n 3 ls
	agent bin important_bak logs statistics_import.log TMP_FORUM_STATS.dmp TMP_TAOBAO_STATS.dmp TMP_TBCAT_STATS.dmp top.dmp worksh
	[oracle@perf_dbc ~]$ nice -n -3 ls
	nice: cannot set priority: Permission denied
 
对root用户，可以给其子进程赋予更小的nice值。

	[root@dbbak root]# nice
	0
	[root@dbbak root]# nice -n -3 ls
	192.168.205.191.txt anaconda-ks.cfg clariion.log Desktop disk1 emc.sh File_sort install.log install.log.syslog log OPS rhel_os_soft root_link_name
 
同样，renice的执行也必须要有相应的权限方可执行。

# 3. 进程生命周期 #


# 4. 进程表示 #

# 5. 进程管理相关的系统调用 #

# 参考资料 #

CFS: https://www.ibm.com/developerworks/cn/linux/l-completely-fair-scheduler/