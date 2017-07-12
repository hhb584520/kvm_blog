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

## 2. ipc ##
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

## 3.链表 ##
http://bbs.chinaunix.net/thread-1981115-1-1.html

http://www.roman10.net/2011/07/28/linux-kernel-programminglinked-list/
如前文所述，Linux内核中的代码，经过稍加改造后，可以在用户态下使用。 
include/linux/list.h 中的函数和宏，是一组精心设计的API，有比较完整的注释和清晰的思路。在用户态下使用list.h，查看改造后的list.h 

## 3.1 举例  ##

下面是用户态下的例子，用以创建、增加、删除和遍历一个双向链表。 

	#include <stdio.h> 
	#include <stdlib.h> 
	
	#include "list.h" 
	
	struct kool_list{ 
	int to; 
	struct list_head list; 
	int from; 
	}; 
	
	int main(int argc, char **argv){ 
	
	struct kool_list *tmp; 
	struct list_head *pos, *q; 
	unsigned int i; 
	
	struct kool_list mylist; 
	INIT_LIST_HEAD(&mylist.list); /*初始化链表头*/ 
	
	/* 给mylist增加元素 */ 
	for(i=5; i!=0; --i){ 
	tmp= (struct kool_list *)malloc(sizeof(struct kool_list)); 
	
	/* 或者INIT_LIST_HEAD(&tmp->list); */ 
	printf("enter to and from:"); 
	scanf("%d %d", &tmp->to, &tmp->from); 
	
	list_add(&(tmp->list), &(mylist.list)); 
	/* 也可以用list_add_tail() 在表尾增加元素*/ 
	} 
	printf("\n"); 
	
	printf("traversing the list using list_for_each()\n"); 
	list_for_each(pos, &mylist.list){ 
	
	/* 在这里 pos->next 指向next 节点, pos->prev指向前一个节点.这里的节点是 
	struct kool_list类型. 但是，我们需要访问节点本身， 而不是节点中的list字段，宏list_entry()正是为此目的。*/ tmp= list_entry(pos, struct kool_list, list); 
	
	printf("to= %d from= %d\n", tmp->to, tmp->from); 
	
	} 
	printf("\n"); 
	/* 因为这是循环链表，也可以以相反的顺序遍历它， 
	*为此，只需要用'list_for_each_prev'代替'list_for_each'， * 也可以调用list_for_each_entry() 对给定类型的节点进行遍历。 
	* 例如: 
	*/ 
	printf("traversing the list using list_for_each_entry()\n"); 
	list_for_each_entry(tmp, &mylist.list, list) 
	printf("to= %d from= %d\n", tmp->to, tmp->from); 
	printf("\n"); 
	
	/*现在，我们可以释放 kool_list节点了.我们本可以调用 list_del()删除节点元素， * 但为了避免遍历链表的过程中删除元素出错，因此调用另一个更加安全的宏 list_for_each_safe()， * 具体原因见后面的分析＊/ 
	
	printf("deleting the list using list_for_each_safe()\n"); 
	list_for_each_safe(pos, q, &mylist.list){ 
	tmp= list_entry(pos, struct kool_list, list); 
	printf("freeing item to= %d from= %d\n", tmp->to, tmp->from); 
	list_del(pos); 
	free(tmp); 
	} 
	
	return 0; 
	}

## 3.2 关于删除元素的不安全性  ##

为什么说调用list_del()删除元素有安全隐患？具体看源代码： 

	/* 
	* Delete a list entry by making the prev/next entries 
	* point to each other. 
	* 
	* This is only for internal list manipulation where we know 
	* the prev/next entries already! 
	*/ 
	static inline void __list_del(struct list_head * prev, struct list_head * next) 
	{ 
	next->prev = prev; 
	prev->next = next; 
	} 
	/** 
	* list_del - deletes entry from list. 
	* @entry: the element to delete from the list. 
	* Note: list_empty on entry does not return true after this, the entry is 
	* in an undefined state. 
	*/ 
	static inline void list_del(struct list_head *entry) 
	{ 
	__list_del(entry->prev, entry->next); 
	entry->next = LIST_POISON1; 
	entry->prev = LIST_POISON2; 
	}

可以看出，当执行删除操作的时候， 被删除的节点的两个指针被指向一个固定的位置（entry->next = LIST_POISON1; entry->prev = LIST_POISON2;）。而list_for_each(pos, head)中的pos指针在遍历过程中向后移动，即pos = pos->next，如果执行了list_del()操作，pos将指向这个固定位置的next, prev,而此时的next, prev没有任何意义，别无选择，出错。 

而list_for_each_safe(p, n, head) 宏解决了上面的问题： 

	/** 
	* list_for_each_safe - iterate over a list safe against removal of list entry 
	* @pos: the &struct list_head to use as a loop counter. 
	* @n: another &struct list_head to use as temporary storage 
	* @head: the head for your list. 
	*/ 
	#define list_for_each_safe(pos, n, head) \ 
	for (pos = (head)->next, n = pos->next; pos != (head); \ 
	pos = n, n = pos->next)

它采用了一个同pos同样类型的指针n 来暂存将要被删除的节点指针pos，从而使得删除操作不影响pos指针！ 

实际上，list.h的设计可谓精益求精，煞费苦心，用简洁的代码突破计算机科学中传统的链表实际机制，不仅考虑了单处理机，还利用了Paul E. McKenney提出的RCU（读拷贝更新）的技术，从而提高了多处理机环境下的性能。关于RCU，请看http://www.rdrop.com/users/paulmck/rclock/ 

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

后记： 
链表，是一个古老而没有新意的话题，关于其分析的文章，也随处可见。之所以重提旧话题，是因为在讲课的过程中，每当我对那些复杂的事物进行剖析 时，剥去一层层外衣，发现，最终的实现都掉落在计算机科学最根本的问题上，比如各种最基本的数据结构，可这些，往往又是学生们不屑一顾的。在此，把链表那拿出来分析，是希冀学子们有时间关注计算机科学的根本问题。

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

## 7.1 自旋锁 ##
   
它提供了一种快速简单的锁实现方法。如果加锁时间不长并且代码不会睡眠（比如中断处理程序），则利用自旋锁时最佳选择。如果加锁时间可能很长或者代码在持有锁时有可能睡眠，那么最好使用信号量来完成加锁功能。

    DEFINE_SPINLOCK(mr_lock);
    spin_lock(&mr_lock);
    临界区
    spin_unlock(&mr_lock);

## 7.2 信号量 ##
   
Linux 中的信号量是一种睡眠锁。如果有一个任务视图获得一个不可用的信号量时，信号量会将其推进一个等待队列，然后让其睡眠。这时处理器能重获自由，从而去执行其他代码。当持有的信号量可用后，处于等待队列中的那个任务将被唤醒，并获得该信号量。
你可以再持有信号量时去睡眠，因为当其它进程试图获得同一信号量时不会因此而死锁。
你在占用信号量的同时不能占用自旋锁。因为在你等待信号量时可能会睡眠，而在持有自旋锁时是不允许睡眠的。

	/*
	 ============================================================================
	 Name        : sept.c
	 Author      : hbhuang
	 Version     :
	 Copyright   : Your copyright notice
	 Description : Hello World in C, Ansi-style
	 ============================================================================
	 */
	
	#include <stdio.h>
	#include <unistd.h>
	#include <stdlib.h>
	#include <pthread.h>
	#include <semaphore.h>
	#include <string.h>
	
	void *thread_function(void *arg);
	pthread_mutex_t work_mutex;
	#define WOKE_SIZE 1024
	char work_area[1024];
	int time_to_exit = 0;
	
	int main(int argc, char *argv[]) {
	    int res;
	    pthread_t a_thread;
	    void *thread_result;
	    res = pthread_mutex_init(&work_mutex, NULL);
	    if(res!=0)
	    {
	        printf("mutex init failed!\n");
	        exit(EXIT_FAILURE);
	    }
	
	    res = pthread_create(&a_thread, NULL, thread_function, NULL);
	    if(res != 0)
	    {
	        printf("Thread creation failed\n");
	        exit(EXIT_FAILURE);
	    }
	    pthread_mutex_lock(&work_mutex);
	    printf("Input some text. Enter 'end' to finish\n");
	    while(!time_to_exit)
	           {
	        fgets(work_area, WOKE_SIZE, stdin);
	        pthread_mutex_unlock(&work_mutex);
	        while(1)
	                     {
	            pthread_mutex_lock(&work_mutex);
	            if(work_area[0] != '\0')
	                                {
	                pthread_mutex_unlock(&work_mutex);
	                usleep(1);
	                                }
	            else
	                break;
	                     }
	           }
	    pthread_mutex_unlock(&work_mutex);
	    printf("\n Waiting for thread to finish...\n");
	    res = pthread_join(a_thread, &thread_result);
	    if(res != 0)
	           {
	        printf("Thread join failed");
	        exit(EXIT_FAILURE);
	           }
	    printf("Thread join\n");
	    pthread_mutex_destroy(&work_mutex);
	    return EXIT_SUCCESS;
	}
	
	void *thread_function(void *arg)
	{
	    usleep(1);
	    pthread_mutex_lock(&work_mutex);
	    while(strncmp("end", work_area, 3) != 0)
	           {
	        printf("You intput %d characters\n", strlen(work_area)-1);
	        printf("the characters is %s", work_area);
	        work_area[0]='\0';
	        //pthread_mutex_unlock(&work_mutex);
	        //usleep(1);
	        //pthread_mutex_lock(&work_mutex);
	        while(work_area[0] == '\0')
	                     {
	            pthread_mutex_unlock(&work_mutex);
	            usleep(1);
	            pthread_mutex_lock(&work_mutex);
	                     }
	           }
	    time_to_exit = 1;
	    work_area[0] = '\0';
	    pthread_mutex_unlock(&work_mutex);
	    pthread_exit(0);
	}


## 7.3 互斥体 ##
    
它是一个简化版的信号量，因为不再需要管理任何使用计数。它适合的使用场景如下：
 
给mutex上锁者必须负责给其再解锁——你不能在一个上下文中锁定一个mutex，而在另一个上下文中给它解锁。这个限制使得 mutex 不适合内核同用户空间复杂的同步场景。最常使用的方式是：在同一上下文中上锁和解锁。
递归地上锁和解锁是不允许的。也就是说，你不能递归地持有同一个锁，同样你也不能再去解锁一个已经被解开的 mutex。
当持有一个 mutex时，进程不可以退出。
mutex 不能在中断或者下半部中使用，即使使用 mutex_trylock() 也不行
mutex 只能通过官方API管理：它只能使用上节中描述的方法初始化，不可被拷贝、手动初始化或者重复初始化。

## 7.4 顺序锁 ##
   
http://www.wowotech.net/kernel_synchronization/seqlock.html

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

## 7.5 RCU(read-copy-update) ##
   
读取-复制-更新，也是一种高级的互斥机制，在正确的条件下，也可获得高的性能。对于被RCU保护的共享数据结构，读者不需要获得任何锁就可以访问它，但写者在访问它时首先拷贝一个副本，然后对副本进行修改，最后使用一个回调机制在适当的时机把指向原来数据的指针重新指向新的被修改的数据。这个时机就是所有引用该数据的CPU都退出对共享数据的操作。

https://www.ibm.com/developerworks/cn/linux/l-rcu/

# 8. 中断 #
  
KVM: Posted Interrupt
Posted Interrupt 允许APIC中断直接注入到guest而不需要VM-Exit

-  需要给guest传递中断的时候，如果vcpu正在运行，那么更新posted-intrrupt请求位图，并向vcpu发送通知，vcpu自动处理该中断，不需要软件干预
-  如果vcpu没有在运行或者已经有通知事件pending，那么什么都不做，中断会在下次VM-Entry的时候处理
-  Posted Interrupt需要一个特别的IPI来给Guest传递中断，并且有较高的优先级，不能被阻塞
-  “acknowledge interrupt on exit”允许中断CPU运行在non-root模式产生时，可以被VMX的handler处理，而不是IDT的handler处理

## 8.1 软中断(下半部机制)


http://unicornx.github.io/2016/04/19/20160419-lk-drv-th-bh/

# 9. 通知链技术 #

## 9.1 概念 ##

大多数内核子系统都是相互独立的，因此某个子系统可能对其它子系统产生的事件感兴趣。为了满足这个需求，也即是让某个子系统在发生某个事件时通知其它的子系统，Linux内核提供了通知链的机制。通知链表只能够在内核的子系统之间使用，而不能够在内核与用户空间之间进行事件的通知。 通知链表是一个函数链表，链表上的每一个节点都注册了一个函数。当某个事情发生时，链表上所有节点对应的函数就会被执行。所以对于通知链表来说有一个通知方与一个接收方。在通知这个事件时所运行的函数由被通知方决定，实际上也即是被通知方注册了某个函数，在发生某个事件时这些函数就得到执行。其实和系统调用signal的思想差不多。

## 9.2 数据结构： ##

通知链有四种类型：

原子通知链（ Atomic notifier chains ）：通知链元素的回调函数（当事件发生时要执行的函数）只能在中断上下文中运行，不允许阻塞。对应的链表头结构：

	struct atomic_notifier_head 
	{
	    spinlock_t lock;
	    struct notifier_block *head;
	};

可阻塞通知链（ Blocking notifier chains ）：通知链元素的回调函数在进程上下文中运行，允许阻塞。对应的链表头：

	struct blocking_notifier_head 
	{
	    struct rw_semaphore rwsem;
	    struct notifier_block *head;
	};

原始通知链（ Raw notifier chains ）：对通知链元素的回调函数没有任何限制，所有锁和保护机制都由调用者维护。对应的链表头：

	struct raw_notifier_head 
	{
	    struct notifier_block *head;
	};

SRCU 通知链（ SRCU notifier chains ）：可阻塞通知链的一种变体。对应的链表头：

	struct srcu_notifier_head 
	{
	    struct mutex mutex;
	    struct srcu_struct srcu;
	    struct notifier_block *head;
	};

通知链的核心结构：

	struct notifier_block 
	{
	    int (*notifier_call)(struct notifier_block *, unsigned long,void *);
	    struct notifier_block *next;
	    int priority;
	};

其中notifier_call是通知链要执行的函数指针，next用来连接其它的通知结构，priority是这个通知的优先级，同一条链上的notifier_block{}是按优先级排列的。内核代码中一般把通知链命名为xxx_chain, xxx_nofitier_chain这种形式的变量名。

## 9.3 运作机制： ##

通知链的运作机制包括两个角色：

被通知者：对某一事件感兴趣一方。定义了当事件发生时，相应的处理函数，即回调函数。但需要事先将其注册到通知链中（被通知者注册的动作就是在通知链中增加一项）。
通知者：事件的通知者。当检测到某事件，或者本身产生事件时，通知所有对该事件感兴趣的一方事件发生。他定义了一个通知链，其中保存了每一个被通知者对事件的处理函数（回调函数）。通知这个过程实际上就是遍历通知链中的每一项，然后调用相应的事件处理函数。
包括以下过程：

通知者定义通知链。
被通知者向通知链中注册回调函数。
当事件发生时，通知者发出通知（执行通知链中所有元素的回调函数）。
被通知者调用 notifier_chain_register 函数注册回调函数，该函数按照优先级将回调函数加入到通知链中：

	static int notifier_chain_register(struct notifier_block **nl,struct notifier_block *n)
	{
	    while ((*nl) != NULL) 
	    {
	        if (n->priority > (*nl)->priority)
	        break;
	        nl = &((*nl)->next);
	    }
	    
	    n->next = *nl;
	    rcu_assign_pointer(*nl, n);
	    
	    return 0;
	}

注销回调函数则使用 notifier_chain_unregister 函数，即将回调函数从通知链中删除：

	static int notifier_chain_unregister(struct notifier_block **nl,struct notifier_block *n)
	{
	    while ((*nl) != NULL) 
	    {
	        if ((*nl) == n) 
	        {
	            rcu_assign_pointer(*nl, n->next);
	        
	            return 0;
	        }
	    
	        nl = &((*nl)->next);
	    }
	    
	    return -ENOENT;
	}

通知者调用 notifier_call_chain 函数通知事件的到达，这个函数会遍历通知链中所有的元素，然后依次调用每一个的回调函数（即完成通知动作）：

	static int __kprobes notifier_call_chain(struct notifier_block**nl, unsigned long val, void *v, int nr_to_call, int *nr_calls)
	{
	    int ret = NOTIFY_DONE;
	    struct notifier_block *nb, *next_nb;
	    
	    nb = rcu_dereference(*nl);
	    
	    while (nb && nr_to_call) 
	    {
	        next_nb = rcu_dereference(nb->next);
	    
	#ifdef CONFIG_DEBUG_NOTIFIERS
	        if(unlikely(!func_ptr_is_kernel_text(nb->notifier_call))) 
	        {
	            WARN(1, "Invalid notifier called!");
	            
	            nb = next_nb;
	            
	            continue;
	        }
	#endif
	
	        ret = nb->notifier_call(nb, val, v);
	        
	        if (nr_calls)
	        
	        (*nr_calls)++;
	        
	        if ((ret & NOTIFY_STOP_MASK) == NOTIFY_STOP_MASK)
	        
	        break;
	        
	        nb = next_nb;
	        
	        nr_to_call--;
	    }
	    
	    return ret;
	}

参数nl是通知链的头部，val表示事件类型，v用来指向通知链上的函数执行时需要用到的参数，一般不同的通知链，参数类型也不一样，例如当通知一个网卡被注册时，v就指向net_device结构，nr_to_call表示准备最多通知几个，-1表示整条链都通知，nr_calls非空的话，返回通知了多少个。

每个被执行的notifier_block回调函数的返回值可能取值为以下几个：

- NOTIFY_DONE：表示对相关的事件类型不关心。
- NOTIFY_OK：顺利执行。
- NOTIFY_BAD：执行有错。
- NOTIFY_STOP：停止执行后面的回调函数。
- NOTIFY_STOP_MASK：停止执行的掩码。

Notifier_call_chain()把最后一个被调用的回调函数的返回值作为它的返回值。

四、举例应用：

在这里，写了一个简单的通知链表的代码。实际上，整个通知链的编写也就两个过程：

首先是定义自己的通知链的头节点，并将要执行的函数注册到自己的通知链中。
其次则是由另外的子系统来通知这个链，让其上面注册的函数运行。
      这里将第一个过程分成了两步来写，第一步是定义了头节点和一些自定义的注册函数（针对该头节点的），第二步则是使用自定义的注册函数注册了一些通知链节点。分别在代码buildchain.c与regchain.c中。发送通知信息的代码为notify.c。

代码1 buildchain.c。它的作用是自定义一个通知链表test_chain，然后再自定义两个函数分别向这个通知链中加入或删除节点，最后再定义一个函数通知这个test_chain链：

	#include <asm/uaccess.h>
	#include <linux/types.h>
	#include <linux/kernel.h>
	#include <linux/sched.h>
	#include <linux/notifier.h>
	#include <linux/init.h>
	#include <linux/types.h>
	#include <linux/module.h>
	MODULE_LICENSE("GPL");
	
	/*
	* 定义自己的通知链头结点以及注册和卸载通知链的外包函数
	*/
	
	/*
	* RAW_NOTIFIER_HEAD是定义一个通知链的头部结点，
	* 通过这个头部结点可以找到这个链中的其它所有的notifier_block
	*/
	static RAW_NOTIFIER_HEAD(test_chain);
	
	/*
	* 自定义的注册函数，将notifier_block节点加到刚刚定义的test_chain这个链表中来
	* raw_notifier_chain_register会调用notifier_chain_register
	*/
	int register_test_notifier(struct notifier_block *nb)
	{
	  return raw_notifier_chain_register(&test_chain, nb);
	}
	EXPORT_SYMBOL(register_test_notifier);
	
	int unregister_test_notifier(struct notifier_block *nb)
	{
	  return raw_notifier_chain_unregister(&test_chain, nb);
	}
	EXPORT_SYMBOL(unregister_test_notifier);
	
	/*
	* 自定义的通知链表的函数，即通知test_chain指向的链表中的所有节点执行相应的函数
	*/
	int test_notifier_call_chain(unsigned long val, void *v)
	{
	  return raw_notifier_call_chain(&test_chain, val, v);
	}
	EXPORT_SYMBOL(test_notifier_call_chain);
	
	/*
	* init and exit 
	*/
	static int __init init_notifier(void)
	{
	  printk("init_notifier\n");
	  return 0;
	}
	
	static void __exit exit_notifier(void)
	{
	    printk("exit_notifier\n");
	}
	
	module_init(init_notifier);
	module_exit(exit_notifier);

代码2 regchain.c。该代码的作用是将test_notifier1 test_notifier2 test_notifier3这三个节点加到之前定义的test_chain这个通知链表上，同时每个节点都注册了一个函数：

	#include <asm/uaccess.h>
	#include <linux/types.h>
	#include <linux/kernel.h>
	#include <linux/sched.h>
	#include <linux/notifier.h>
	#include <linux/init.h>
	#include <linux/types.h>
	#include <linux/module.h>
	MODULE_LICENSE("GPL");
	
	/*
	* 注册通知链
	*/
	extern int register_test_notifier(struct notifier_block*);
	extern int unregister_test_notifier(struct notifier_block*);
	
	static int test_event1(struct notifier_block *this, unsignedlong event, void *ptr)
	{
	  printk("In Event 1: Event Number is %d\n", event);
	  return 0; 
	}
	
	static int test_event2(struct notifier_block *this, unsignedlong event, void *ptr)
	{
	  printk("In Event 2: Event Number is %d\n", event);
	  return 0; 
	}
	
	static int test_event3(struct notifier_block *this, unsignedlong event, void *ptr)
	{
	  printk("In Event 3: Event Number is %d\n", event);
	  return 0; 
	}
	
	/*
	* 事件1，该节点执行的函数为test_event1
	*/
	static struct notifier_block test_notifier1 =
	{
	    .notifier_call = test_event1,
	};
	
	/*
	* 事件2，该节点执行的函数为test_event1
	*/
	static struct notifier_block test_notifier2 =
	{
	    .notifier_call = test_event2,
	};
	
	/*
	* 事件3，该节点执行的函数为test_event1
	*/
	static struct notifier_block test_notifier3 =
	{
	    .notifier_call = test_event3,
	};
	
	/*
	* 对这些事件进行注册
	*/
	static int __init reg_notifier(void)
	{
	  int err;
	  printk("Begin to register:\n");
	  
	  err = register_test_notifier(&test_notifier1);
	  if (err)
	  {
	    printk("register test_notifier1 error\n");
	    return -1; 
	  }
	  printk("register test_notifier1 completed\n");
	
	  err = register_test_notifier(&test_notifier2);
	  if (err)
	  {
	    printk("register test_notifier2 error\n");
	    return -1; 
	  }
	  printk("register test_notifier2 completed\n");
	
	  err = register_test_notifier(&test_notifier3);
	  if (err)
	  {
	    printk("register test_notifier3 error\n");
	    return -1; 
	  }
	  printk("register test_notifier3 completed\n");
	  
	  return err;
	}
	
	/*
	* 卸载刚刚注册了的通知链
	*/
	static void __exit unreg_notifier(void)
	{
	  printk("Begin to unregister\n");
	  unregister_test_notifier(&test_notifier1);
	  unregister_test_notifier(&test_notifier2);
	  unregister_test_notifier(&test_notifier3);
	  printk("Unregister finished\n");
	}
	
	module_init(reg_notifier);
	module_exit(unreg_notifier);

代码3 notify.c。该代码的作用就是向test_chain通知链中发送消息，让链中的函数运行：

	#include <asm/uaccess.h>
	#include <linux/types.h>
	#include <linux/kernel.h>
	#include <linux/sched.h>
	#include <linux/notifier.h>
	#include <linux/init.h>
	#include <linux/types.h>
	#include <linux/module.h>
	MODULE_LICENSE("GPL");
	
	extern int test_notifier_call_chain(unsigned long val, void *v);
	
	/*
	* 向通知链发送消息以触发注册了的函数
	*/
	static int __init call_notifier(void)
	{
	  int err;
	  printk("Begin to notify:\n");
	
	  /*
	  * 调用自定义的函数，向test_chain链发送消息
	  */
	  printk("==============================\n");
	  err = test_notifier_call_chain(1, NULL);
	  printk("==============================\n");
	  if (err)
	          printk("notifier_call_chain error\n");
	  return err;
	}
	
	static void __exit uncall_notifier(void)
	{
	    printk("End notify\n");
	}
	
	module_init(call_notifier);
	module_exit(uncall_notifier);

Makefile文件：

	obj-m:=buildchain.o regchain.o notify.o
	CURRENT_PATH := $(shell pwd)
	LINUX_KERNEL := $(shell uname -r)
	KERNELDIR := /usr/src/linux-headers-$(LINUX_KERNEL)
	
	all:
	make -C $(KERNELDIR) M=$(CURRENT_PATH) modules
	
	clean:
	
	make -C $(KERNELDIR) M=$(CURRENT_PATH) clean 

运行（注意insmod要root权限）：

	make
	
	insmod buildchain.ko
	insmod regchain.ko
	insmod notify.ko

这样就可以看到通知链运行的效果了：

	init_notifier
	Begin to register:
	register test_notifier1 completed
	register test_notifier2 completed
	register test_notifier3 completed
	Begin to notify:
	==============================
	In Event 1: Event Number is 1
	In Event 2: Event Number is 1
	In Event 3: Event Number is 1
	==============================

# 10.signal #

http://www.spongeliu.com/165.html

# 11.How to search function header file ##
Please do not use non-standard header files (e.g. malloc.h,linux/fcntl.h). They can cause portability problems, such as what Paul encountered.
   
If you are not sure which ones are standard, please look at the  man pages of corresponding functions (e.g. man 2 open, man malloc).

# 12. Others
## 12.1 kernel parameters
https://www.kernel.org/doc/Documentation/kernel-parameters.txt

http://www.jinbuguo.com/

## 12.2 license
1.BSD类许可证，允许随意商业集成。
2.MPL类许可证，修改后的源代码需公开。
3.GPL类许可证，传染性/商业不友好。

# 参考资料 #

缺页处理  
http://blog.csdn.net/mihouge/article/details/6955398