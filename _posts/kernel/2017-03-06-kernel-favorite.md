# 内核编程 #
相对于用户空间内应用程序的开发，内核开发有很大的不同

- 内核编程时不能访问C库
- 内核编程必须使用 GNU C
- 内核编程时缺乏像用户空间那样的内存保护机制
- 内核编程时浮点数很难使用
- 内核只有一个很小的定长堆栈
- 由于内核支持异步中断、抢占和SMP，因此必须时刻注意同步和开发
- 要考虑可移植性的重要性。

Linux内核学习书籍推荐

- 《Linux内核完全注释3.0》
- 《深入Linux内核架构》
- 《操作系统内存分配原理》
- 《深入分析Linux内核源代码》
- 《Linux服务器性能调整》
- 《Linux内核设计与实现》
- 《深入理解Linux内核》
 

## 1. copy_from_user ##
最近貌似有人问为什么要用copy_from_user这类函数的问题，难道内核不能使用用户态的指针吗？那人自己做了个实验，不用copy_from_user，而是直接在内核里使用用户态指针，程序运行得好好的，啥事也没有。那么内核干嘛还要提供这么些函数呢？

我看网上有人说用户态指针在内核里没有意义了，如同内核指针在用户态一样没有意义了。这话其实不对，以x86来说，页目录表是放在CR3中的，这个寄存器 没有什么内核态用户态之分，换句话说一个用户态进程通过系统调用进入内核态，task_struct结构中的cr3都是不变的，没有页目录表变化的情况发 生。所以内核态使用用户进程传递过来的指针是有意义的，而且在用户态下内核的指针也是有意义的，只不过因为权限不够，用户进程使用内核指针就有异常发生。 

回到上面的话题，既然内核可以使用用户进程传递过来的指针，那干吗不使用memcpy呢？绝大多数情况下使用memcpy取代 copy_from_user都是OK的，事实上在没有MMU的体系上，copy_from_user就是memcpy。但是为什么有MMU就不一样了 呢，使用copy_from_user除了那个access_ok检查之外，它的实现前半部分就是memcpy，后边多了个两个section。这话要得 从内核提供的缺页异常说起，而且copy_from_user就是用来对付用户态的指针所指向的虚拟地址没有映射到实际物理内存这种情况，这个现象在用户 空间不是什么大事，缺页异常会自动提交物理内存，之后发生异常的指令正常运行，彷佛啥事也没发生。但是这事放到内核里就不一样了，内核需要显式地去修正这 个异常，背后的思想是：内核对于没有提交物理地址的虚拟地址空间的访问不能象用户进程那样若无其事，内核得表明下态度--别想干坏事，老子盯着你呢。就这 么个意思。所以copy_from_user和memcpy的区别就是多了两个section，这样对于缺页的异常，copy_from_user可以修 正，但是memcpy不行。 

我后来想能不能想个办法验证一下，在网上看到有人说用户空间的malloc是先分配虚拟空间，用到的时候才映射物理地址。这正好满足我们的要求，结果不是 很理想，我不知道这个malloc到底内核是不是有类似copy-on-write这样大的特性，总之memcpy对这种情况没有报任何异常。那就干脆来 狠的，直接估摸着一个可能还没被映射的用户空间的虚地址，传递给了内核空间的驱动程序，于是问题来了：memcpy发生了 oops，copy_from_user正常运行了。 

看来两者之间就这点区别了，至于access_ok，看过源码的人都知道那不过是验证一下地址范围而已，我开始还以为这个函数会操作页目录表，事实上完全不是。

##2. ipc##
https://www.ibm.com/developerworks/cn/linux/l-ipc/

管道通信（父子进程）
 
	#include <stdio.h>
	#include <stdlib.h>
	#define MAXLINE 100
	int main(void){
		int		n, fd[2];
		pid_t	pid;
		if(pipe(fd) < 0)		printf("pipe error!\n");
		if((pid = fork()) < 0)	printf("fork error!\n");
		else if (pid > 0){		// parent
			close(fd[0]);
			write(fd[1], "hello world\n", 12);
		else{					// child
			close(fd[1]);
			n = read(fd[0], line, MAXLINE);
			write(STDOUT_FILENO, line, n);
		}
		exit(0);
	}

## 3.list_for_each_entry ##
http://bbs.chinaunix.net/thread-1981115-1-1.html

在Linux内核源码中，经常要对链表进行操作，其中一个很重要的宏是list_for_each_entry：
意思大体如下：
假设只有两个结点，则第一个member代表head，
list_for_each_entry的作用就是循环遍历每一个pos中的member子项。


	pos:                                        pos:
	_________________________                   _________________________
	|                       |                   |                       |
	|                       |                   |                       |
	|    ...........        |                   |   ................    |
	|                       |                   |                       |
	|                       |                   |                       |
	|   member:             |          _________|__> member             |
	|   {                   |          |        |    {                  |
	|        *prev;         |          |        |       *prev;          |
	|        *next;       --|----------         |        *next;-------------
	|    }                  |                   |    }                  |  |
	|—^————-----------------|                   |_______________________|  |
	  |                                                                    |
	  |                                                                    |
	  |____________________________________________________________________|


## 4.kernel sleep 2 seconds ##
使用方式： 

    set_current_state(TASK_INTERRUPTIBLE); 
    schedule_timeout(2*HZ); /* 睡2秒 */ 
    进程经过2秒后会被唤醒。如果不希望被用户空间打断，可以将进程状态设置为TASK_UNINTERRUPTIBLE。 
 
	#include <linux/init.h>   
	#include <linux/module.h>   
	#include <linux/time.h>   
	#include <linux/sched.h>   
	#include <linux/delay.h>   
	  
	static int __init test_init(void)  
	{  
	    set_current_state(TASK_INTERRUPTIBLE);  
	    schedule_timeout(5 * HZ);  
	    printk(KERN_INFO "Hello Micky\n");  
	    return 0;  
	}  
	  
	static void __exit test_exit(void)  
	{  
	}  
	  
	module_init(test_init);  
	module_exit(test_exit);  
	  
	MODULE_LICENSE("GPL");  
	MODULE_AUTHOR("Haibin");  
	MODULE_DESCRIPTION("Test for delay");  



## 5. Linux代码走读基础 ##
5.1 __attribute__，属性描述符，用来设置一个函数、数据结构、类型的属性。如 __attribute__（pure）

	void fetal_error() __attribute__(noreturn);               声明函数：无返回值
	__attribute__((noinline)) int foo1(){……}                  定义函数：不扩展为内联函数
	int getlim() __attribute__((pure, noinline));        声明函数：不内联，不修改全局变量
	void mspec(void) __attribute__((section(“specials”)));     声明函数：连接到特定节中
	补充：除非使用-O优化级别，否则函数不会真正的内联。
	__attribute__((constructor)) 构造函数

5.2 __init，指放在init.text，并且只在某个时候利用，用完则不在使用，如start_kernel

5.3 asmlinage（不用寄存器挂载参数，用桟，它和asmregparm对应，它只用3个寄存器）

5.4 typeof（获得变量的类型）

5.5 错误（ERR_PTR，返回内存错误；IS_ERR；PTR_ERR，获得错误码）

5.6 Sparse语法检查， 它是Linus自己发明的一个语法检查工具，在gcc编译阶段时可以调用

5.7 #define notrace __attribute__
    对于应用程序，函数的运行是可以被trace的，然而对于内核，内核是在自己的内部实现了一个 ftrace的机制，编译内核的时候，如果打开这个选项，那么通过挂载一个debugfs的文件系统来进行相应内容的显示。因为在进行函数调用流程的显示过程中，是使用了两个FTRACE特殊的函数，当函数被调用与函数被执行完返回之前，都会分别调用这两个特别的函数。如果不把这两个函数指定为不被跟踪的，那么整个跟踪过程就会陷入一个无限循环当中。

5.8 violatile，编译器对内存位置的优化，即不优化到寄存器中，只从内存中读取其真实数据。

5.9 编译器对指令序列的优化--CPU流水线引起的问题
      超标量实际上就是一个CPU拥有多条独立的流水线，一次可以发射多条指令。因此，允许很多指令的乱序执行
加一条 M()即可解决
__asm__ __violatile__ ("": : :"memory")
__asm__ 用于指示编译器在此插入汇编语句
__violatile__ 用于告诉编译器，严禁将此处的汇编语句及其它重复的语句重组合优化。
": : :" 表示空指令
"memory" 强制gcc编译器假设所有内存单元均被汇编指令修改。
5.10 restrict
    它只可用于指针，并表明指针是访问一个数据对象的惟一且初始的方式。
5.11 __func__  当前函数名
        __file__    当前文件名
5.12 #pragma，在现代的编译器中，可用命令行参数或IDE菜单修改编译器的某些设置，也可用 #pragma将编译器指令置于源代码中。

## 6. 线程创建的Linux实现 ##
我们知道，Linux的线程实现是在核外进行的，核内提供的是创建进程的接口do_fork()。内核提供了两个系统调用__clone()和fork ()，最终都用不同的参数调用do_fork()核内API。当然，要想实现线程，没有核心对多进程（其实是轻量级进程）共享数据段的支持是不行的，因此，do_fork()提供了很多参数，包括CLONE_VM（共享内存空间）、CLONE_FS（共享文件系统信息）、CLONE_FILES（共享文件描述符表）、CLONE_SIGHAND（共享信号句柄表）和CLONE_PID（共享进程ID，仅对核内进程，即0号进程有效）。当使用fork系统调用时，内核调用do_fork()不使用任何共享属性，进程拥有独立的运行环境，而使用pthread_create()来创建线程时,则最终设置了所有这些属性来调用__clone()，而这些参数又全部传给核内的do_fork()，从而创建的"进程"拥有共享的运行环境，只有栈是独立的，由 __clone()传入。

Linux线程在核内是以轻量级进程的形式存在的，拥有独立的进程表项，而所有的创建、同步、删除等操作都在核外pthread库中进行。pthread 库使用一个管理线程（__pthread_manager()，每个进程独立且唯一）来管理线程的创建和终止，为线程分配线程ID，发送线程相关的信号（比如Cancel），而主线程（pthread_create()）的调用者则通过管道将请求信息传给管理线程。

﻿﻿
## 7.Linux同步和多线程技术  ##

- 原子操作 
- 睡眠及等待的时间长短 
- 读写比 
- 自旋锁，信号量，互斥体，顺序 锁，读写锁，RCU等等。
- rmb读内存屏障，在该方法之前的 载入操作不会被重新排在该调用之 后。

7.1 自旋锁
   
它提供了一种快速简单的锁实现方法。如果加锁时间不长并且代码不会睡眠（比如中断处理程序），则利用自旋锁时最佳选择。如果加锁时间可能很长或者代码在持有锁时有可能睡眠，那么最好使用信号量来完成加锁功能。

    DEFINE_SPINLOCK(mr_lock);
    spin_lock(&mr_lock);
    临界区
    spin_unlock(&mr_lock);

7.2 信号量
   
Linux 中的信号量是一种睡眠锁。如果有一个任务视图获得一个不可用的信号量时，信号量会将其推进一个等待队列，然后让其睡眠。这时处理器能重获自由，从而去执行其他代码。当持有的信号量可用后，处于等待队列中的那个任务将被唤醒，并获得该信号量。
你可以再持有信号量时去睡眠，因为当其它进程试图获得同一信号量时不会因此而死锁。
你在占用信号量的同时不能占用自旋锁。因为在你等待信号量时可能会睡眠，而在持有自旋锁时是不允许睡眠的。

7.3 互斥体
    
它是一个简化版的信号量，因为不再需要管理任何使用计数。它适合的使用场景如下：
 
给mutex上锁者必须负责给其再解锁——你不能在一个上下文中锁定一个mutex，而在另一个上下文中给它解锁。这个限制使得 mutex 不适合内核同用户空间复杂的同步场景。最常使用的方式是：在同一上下文中上锁和解锁。
递归地上锁和解锁是不允许的。也就是说，你不能递归地持有同一个锁，同样你也不能再去解锁一个已经被解开的 mutex。
当持有一个 mutex时，进程不可以退出。
mutex 不能在中断或者下半部中使用，即使使用 mutex_trylock() 也不行
mutex 只能通过官方API管理：它只能使用上节中描述的方法初始化，不可被拷贝、手动初始化或者重复初始化。

7.4 顺序锁
   
顺序锁，通常简称 seq 锁，是在2.6版本内核中才引入的一种新型锁。这种锁提供了一种很简单的机制，用于读写共享数据。实现这种锁主要依靠一个序列计数器。当有疑义的数据被写入时，会得到一个锁，并且序列值会增加。在读取序列值之前或之后，序列号都被读取。如果读取的序列号值相同，说明在读操作进行的过程中没有被写操作打断过。此外，如果读取的值是偶数，那么就表明写操作没有发生（要明白因为锁的初值是0，所以写锁会使值成为奇数，释放的时候就变成偶数）。适合以下情况

*  你的数据存在很多读者。
*  你的数据写者很少。
*  虽然写者很少，但是你希望写优先于读，而且不允许读者让写者饥饿。
*  你的数据很简单，如简单结构，甚至是简单的整型——在某些场合，你是不能使用原子量的。
    
例子：
    u64  get_jiffies_64(void)
    {
           unsigned long seq;
           u64    ret;

           do{
                    seq = read_seqbegin(&xtime_lock);
                    ret  = jiffies_64;
            } while(read_seqretry(&xtime_lock, seq);
            return ret;
    }

    定时器中断会更新 jiffies的值，此刻，也需要使用seq 锁变量：
    write_seqlock(&xtime_lock);
    jiffies_64 += 1;
    write_seqlock(&xtime_lock);

7.5 RCU(read-copy-update)
   
读取-复制-更新，也是一种高级的互斥机制，在正确的条件下，也可获得高的性能。对于被RCU保护的共享数据结构，读者不需要获得任何锁就可以访问它，但写者在访问它时首先拷贝一个副本，然后对副本进行修改，最后使用一个回调机制在适当的时机把指向原来数据的指针重新指向新的被修改的数据。这个时机就是所有引用该数据的CPU都退出对共享数据的操作。具体见另外一篇笔记
        