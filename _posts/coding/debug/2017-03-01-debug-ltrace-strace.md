
# 1. ltrace 和 strace 介绍 #

我们在内核调试的时候，经常想跟踪一下某一个进程的库函数调用或者跟踪每个进程的系统调用，这个时候我们就用到strace和ltrace。 ltrace能够跟踪进程的库函数调用,它会显现出哪个库函数被调用,而strace则是跟踪进程的每个系统调用.
 
下面我们还是用最简单的helloworld说明问题：

	#include <stdio.h>
	
	int	main ()
	{
	    printf("Hello world!\n");
	    return 0;
	}

编译：

	gcc hello.c -o hello

## 1.1 ltrace 使用 ##
用ltrace跟踪hello程序,如下:

	ltrace ./hello
 
	__libc_start_main(0x80483b4, 1, 0xbfeab574, 0x80483e0, 0x80483d0 <unfinished ...>
	puts("Hello World"Hello World
	)                              = 12
	+++ exited (status 0) +++

这里我们注意到puts()库函数打印出字符串。puts()这个函数在内核arch/arm/boot/compressed/head.S有实现，另外，puts()这个函数在uboot代码中也有实现，我们的printf，print都是靠puts函数去实现输出的，大家可以看一下。

 
## 1.2 strace 使用 ##
现在，我们在用strace去跟踪一下hello

	strace ./hello

得到

	execve("./hello", ["./hello"], [/* 41 vars */]) = 0
	brk(0)                                  = 0x9afa000
	access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
	mmap2(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb785d000
	access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
	open("/etc/ld.so.cache", O_RDONLY)      = 3
	fstat64(3, {st_mode=S_IFREG|0644, st_size=61532, ...}) = 0
	mmap2(NULL, 61532, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb784d000
	close(3)                                = 0
	access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
	open("/lib/libc.so.6", O_RDONLY)        = 3
	read(3, "\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0\3\0\1\0\0\0@n\1\0004\0\0\0"..., 512) = 512
	fstat64(3, {st_mode=S_IFREG|0755, st_size=1421892, ...}) = 0
	mmap2(NULL, 1431976, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x507000
	mprotect(0x65e000, 4096, PROT_NONE)     = 0
	mmap2(0x65f000, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x157) = 0x65f000
	mmap2(0x662000, 10664, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x662000
	close(3)                                = 0
	mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb784c000
	set_thread_area({entry_number:-1 -> 6, base_addr:0xb784c6c0, limit:1048575, seg_32bit:1, contents:0, read_exec_only:0, limit_in_pages:1, seg_not_present:0, useable:1}) = 0
	mprotect(0x65f000, 8192, PROT_READ)     = 0
	mprotect(0x8049000, 4096, PROT_READ)    = 0
	mprotect(0xcda000, 4096, PROT_READ)     = 0
	munmap(0xb784d000, 61532)               = 0
	fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
	mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb785c000
	write(1, "Hello World\n", 12Hello World
	)           = 12
	exit_group(0)                           = ?


Linux系统默认分配了3个文件描述符值：0－ standard input，1－standard output，2－standard error。我们看到程序调用write()系统调用做了输出,同时strace还把hello程序运行时所做的系统调用都打印出来了.

# 2. 交叉编译 strace #

strace是一款非常强大的调试用户程序的工具，如在嵌入式平台使用，则需要对其进行交叉编译；以ARM及PPC平台为例，编译strace-4.5.18；

- ARM平台(arm-linux-gcc)

	CC=arm-linux-gcc LD=arm-linux-ld RANLIB=arm-linux-ranlib ./configure --host=arm-linux --target=arm-linux

- PPC平台(ppc-linux-)

	CC=ppc_82xx-gcc LD=ppc_82xx-ld RANLIB=ppc_82xx-ranlib ./configure --host=powerpc-linux --target=powerpc-linux

- DaVinCi平台(arm_v5t_le-gcc)
	CC=arm_v5t_le-gcc LD=arm_v5t_le-ld RANLIB=arm_v5t_le-ranlib ./configure --host=arm-linux --target=arm-linux

    3. 编译

        make && make check

    4. 如果希望安装到指定目录，则在配置时指定 --prefix=/yourdir，编译之后执行make install即可。

 

=================================================================================================================

strace工具是一个非常强大的工具，是调试程序的好工具。要移植到arm平台，就需要使用交叉编译工具编译生成静态链接的可执行文件。具体步骤如下：

1.下载 strace-4.5.16.tar.bz2，不要下载最新的strace-4.5.18.tar.bz2，因为后者编译会出错。下载网址是：http://sourceforge.net/project/showfiles.php?group_id=2861&package_id=2819；

2.解压。对于ARM平台，必须打上一个补丁，补丁在文章的最后面；

3.配置。./configure --host=arm-linux CC=arm_v5t_le-gcc LD=arm_v5t_le-ld；

4.编译。make CFLAGS+="-static",生成strace静态可执行文件，2M多；

5.strip。arm_v5t_le-stip strace，这样可执行文件就减小到600多K。

以上采用的是达芬奇平台的arm工具，也可以直接使用通用的arm-linux-gcc工具，版本3.4.1的我试过，可以编译通过，其他版本的不清楚。


strace的使用介绍可以参考以下两篇文章：
1.http://www.ibm.com/developerworks/cn/aix/library/au-unix-strace.html。
2.http://blog.chinaunix.net/u1/38279/showart_367248.html

 

--- strace-4.5.16-orig/syscall.c 2005-06-08 21:45:28.000000000 +0100
+++ strace-4.5.16/syscall.c 2005-10-25 19:26:39.000000000 +0100
@@ -1045,6 +1045,15 @@ struct tcb *tcp;
/*
* Note: we only deal with only 32-bit CPUs here.
*/
+
+ if (!(tcp->flags & TCB_INSYSCALL) &&
+ (tcp->flags & TCB_WAITEXECVE)) {
+ /* caught a fake syscall from the execve's exit */
+ tcp->flags &= ~TCB_WAITEXECVE;
+ return 0;
+ }
+ 
+
if (regs.ARM_cpsr & 0x20) {
/*
* Get the Thumb-mode system call number




-----------------------------------











引言

“Oops，系统挂死了..."

“Oops，程序崩溃了..."

“Oops，命令执行报错..."

 

对于维护人员来说，这样的悲剧每天都在上演。理想情况下，系统或应用程序的错误日志提供了足够全面的信息，通过查看相关日志，维护人员就能很快地定位出问题发生的原因。但现实情况，许多错误日志打印模凌两可，更多地描述了出错时的现象(比如"could not open file"，"connect to XXX time out")，而非出错的原因。

 

错误日志不能满足定位问题的需求，我们能从更“深层”的方面着手分析吗？程序或命令的执行，需要通过系统调用(system call)与操作系统产生交互，其实我们可以通过观察这些系统调用及其参数、返回值，界定出错的范围，甚至找出问题出现的根因。

 

在Linux中，strace就是这样一款工具。通过它，我们可以跟踪程序执行过程中产生的系统调用及接收到的信号，帮助我们分析程序或命令执行中遇到的异常情况。

 

一个简单的例子

如何使用strace对程序进行跟踪，如何查看相应的输出？下面我们通过一个例子来说明。

1.被跟踪程序示例

复制代码
//main.c
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
int main( )
{
　　int fd ;
　　int i = 0 ;
　　fd = open( “/tmp/foo”, O_RDONLY ) ;
　　if ( fd < 0 )
　　　　i=5;
　　else
　　　　i=2;
　　return i;
}
复制代码
以上程序尝试以只读的方式打开/tmp/foo文件，然后退出，其中只使用了open这一个系统调用函数。之后我们对该程序进行编译，生成可执行文件：

lx@LX:~$ gcc main.c -o main
 

2.strace跟踪输出

使用以下命令，我们将使用strace对以上程序进行跟踪，并将结果重定向至main.strace文件：

lx@LX:~$ strace -o main.strace ./main
接下来我们来看main.strace文件的内容：

复制代码
lx@LX:~$ cat main.strace
1 execve("./main", ["./main"], [/* 43 vars */]) = 0
2 brk(0)                                  = 0x9ac4000
3 access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
4 mmap2(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb7739000
5 access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
6 open("/etc/ld.so.cache", O_RDONLY)      = 3
7 fstat64(3, {st_mode=S_IFREG|0644, st_size=80682, ...}) = 0
8 mmap2(NULL, 80682, PROT_READ, MAP_PRIVATE, 3, 0) = 0xb7725000
9 close(3)                                = 0
10 access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)
11 open("/lib/i386-linux-gnu/libc.so.6", O_RDONLY) = 3
12 read(3, "\177ELF\1\1\1\0\0\0\0\0\0\0\0\0\3\0\3\0\1\0\0\0\220o\1\0004\0\0\0"..., 512) = 512
13 fstat64(3, {st_mode=S_IFREG|0755, st_size=1434180, ...}) = 0
14 mmap2(NULL, 1444360, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x56d000
15 mprotect(0x6c7000, 4096, PROT_NONE)     = 0
16 mmap2(0x6c8000, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x15a) = 0x6c8000
17 mmap2(0x6cb000, 10760, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x6cb000
18 close(3)                                = 0
19 mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb7724000
20 set_thread_area({entry_number:-1 -> 6, base_addr:0xb77248d0, limit:1048575, seg_32bit:1, contents:0, read_exec_    only:0, limit_in_pages:1, seg_not_present:0, useable:1}) = 0
21 mprotect(0x6c8000, 8192, PROT_READ)     = 0
22 mprotect(0x8049000, 4096, PROT_READ)    = 0
23 mprotect(0x4b0000, 4096, PROT_READ)     = 0
24 munmap(0xb7725000, 80682)               = 0
25 open("/tmp/foo", O_RDONLY)              = -1 ENOENT (No such file or directory)
26 exit_group(5)                           = ?
//标红的行号为方便说明而添加，非strace执行输出
复制代码
看到这一堆输出，是否心生畏难情绪？不用担心，下面我们对输出逐条进行分析。

 

strace跟踪程序与系统交互时产生的系统调用，以上每一行就对应一个系统调用，格式为：

系统调用的名称( 参数... ) = 返回值  错误标志和描述

 

Line 1:  对于命令行下执行的程序，execve(或exec系列调用中的某一个)均为strace输出系统调用中的第一个。strace首先调用fork或clone函数新建一个子进程，然后在子进程中调用exec载入需要执行的程序(这里为./main)

Line 2:  以0作为参数调用brk，返回值为内存管理的起始地址(若在子进程中调用malloc，则从0x9ac4000地址开始分配空间)

Line 3:  调用access函数检验/etc/ld.so.nohwcap是否存在

Line 4:  使用mmap2函数进行匿名内存映射，以此来获取8192bytes内存空间，该空间起始地址为0xb7739000，关于匿名内存映射，可以看这里

Line 6:  调用open函数尝试打开/etc/ld.so.cache文件，返回文件描述符为3

Line 7:  fstat64函数获取/etc/ld.so.cache文件信息

Line 8:  调用mmap2函数将/etc/ld.so.cache文件映射至内存，关于使用mmap映射文件至内存，可以看这里

Line 9:  close关闭文件描述符为3指向的/etc/ld.so.cache文件

Line12:  调用read，从/lib/i386-linux-gnu/libc.so.6该libc库文件中读取512bytes，即读取ELF头信息

Line15:  使用mprotect函数对0x6c7000起始的4096bytes空间进行保护(PROT_NONE表示不能访问，PROT_READ表示可以读取)

Line24:  调用munmap函数，将/etc/ld.so.cache文件从内存中去映射，与Line 8的mmap2对应

Line25:  对应源码中使用到的唯一的系统调用——open函数，使用其打开/tmp/foo文件

Line26:  子进程结束，退出码为5(为什么退出值为5？返回前面程序示例部分看看源码吧：)

 

3.输出分析

呼呼！看完这么多系统调用函数，是不是有点摸不着北？让我们从整体入手，回到主题strace上来。

从上面输出可以发现，真正能与源码对应上的只有open这一个系统调用(Line25)，其他系统调用几乎都用于进行进程初始化工作：装载被执行程序、载入libc函数库、设置内存映射等。

 

源码中的if语句或其他代码在相应strace输出中并没有体现，因为它们并没有唤起系统调用。strace只关心程序与系统之间产生的交互，因而strace不适用于程序逻辑代码的排错和分析。

 

对于Linux中几百个系统调用，上面strace输出的几个只是冰山一角，想要更深入地了解Linux系统调用，那就man一下吧！

man 2 系统调用名称
man ld.so  //Linux动态链接的manpage
 

strace常用选项

该节介绍经常用到的几个strace命令选项，以及在何时使用这些选项合适。

1.跟踪子进程

默认情况下，strace只跟踪指定的进程，而不对指定进程中新建的子进程进行跟踪。使用-f选项，可对进程中新建的子进程进行跟踪，并在输出结果中打印相应进程PID：

复制代码
mprotect(0x5b1000, 4096, PROT_READ)     = 0
munmap(0xb77fc000, 80682)               = 0
clone(Process 13600 attached
child_stack=0, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0xb77fb938) = 13600
[pid 13599] fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
[pid 13600] fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
[pid 13599] mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0 <unfinished ...>
[pid 13600] mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb780f000
……
复制代码
对多进程程序、命令和脚本使用strace进行跟踪的时，一般打开-f选项。

 

2.记录系统调用时间

strace还可以记录程序与系统交互时，各个系统调用发生时的时间信息，有r、t、tt、ttt、T等几个选项，它们记录时间的方式为：

-T:   记录各个系统调用花费的时间，精确到微秒

-r:   以第一个系统调用(通常为execve)计时，精确到微秒

-t:   时：分：秒

-tt:  时：分：秒 . 微秒

-ttt: 计算机纪元以来的秒数 . 微秒

比较常用的为T选项，因为其提供了每个系统调用花费时间。而其他选项的时间记录既包含系统调用时间，又算上用户级代码执行用时，参考意义就小一些。对部分时间选项我们可以组合起来使用，例如：

复制代码
strace -Tr ./main
0.000000 execve(“./main”, [“main”], [/* 64 vars */]) = 0
0.000931 fcntl64(0, F_GETFD)= 0 <0.000012>
0.000090 fcntl64(1, F_GETFD)= 0 <0.000022>
0.000060 fcntl64(2, F_GETFD)= 0 <0.000012>
0.000054 uname({sys=”Linux”, node=”ion”, ...}) = 0 <0.000014>
0.000307 geteuid32()= 7903 <0.000011>
0.000040 getuid32()= 7903 <0.000012>
0.000039 getegid32()= 200 <0.000011>
0.000039 getgid32()= 200 <0.000011>
……
复制代码
最左边一列为-r选项对应的时间输出，最右边一列为-T选项对应的输出。

 

3.跟踪正在运行的进程

使用strace对运行中的程序进行跟踪，使用命令“strace -p PID”即可，命令执行之后，被跟踪的进程照常执行，strace的其他选项也适用于运行中的进程跟踪。

 

使用strace处理程序挂死

最后我们通过一个程序示例，学习使用strace分析程序挂死的方法。

1.挂死程序源码

复制代码
//hang.c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

int main(int argc, char** argv)
{
    getpid(); //该系统调用起到标识作用
    if(argc < 2)
    {
        printf("hang (user|system)\n");
        return 1;
    }
    if(!strcmp(argv[1], "user"))
        while(1);
    else if(!strcmp(argv[1], "system"))
        sleep(500);
    return 0;
}
复制代码
可向该程序传送user和system参数，以上代码使用死循环模拟用户态挂死，调用sleep模拟内核态程序挂死。


2.strace跟踪输出

用户态挂死跟踪输出：

复制代码
lx@LX:~$ gcc hang.c -o hang
lx@LX:~$ strace ./hang user
……
mprotect(0x8049000, 4096, PROT_READ)    = 0
mprotect(0xb59000, 4096, PROT_READ)     = 0
munmap(0xb77bf000, 80682)               = 0
getpid()                                = 14539
复制代码
内核态挂死跟踪输出：

复制代码
lx@LX:~$ strace ./hang system
……
mprotect(0x8049000, 4096, PROT_READ)    = 0
mprotect(0xddf000, 4096, PROT_READ)     = 0
munmap(0xb7855000, 80682)               = 0
getpid()                                = 14543
rt_sigprocmask(SIG_BLOCK, [CHLD], [], 8) = 0
rt_sigaction(SIGCHLD, NULL, {SIG_DFL, [], 0}, 8) = 0
rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
nanosleep({500, 0}, 
复制代码
 

3.输出分析

用户态挂死情况下，strace在getpid()一行输出之后没有其他系统调用输出；进程在内核态挂死，最后一行的系统调用nanosleep不能完整显示，这里nanosleep没有返回值表示该调用尚未完成。

 

因而我们可以得出以下结论：使用strace跟踪挂死程序，如果最后一行系统调用显示完整，程序在逻辑代码处挂死；如果最后一行系统调用显示不完整，程序在该系统调用处挂死。

 

当程序挂死在系统调用处，我们可以查看相应系统调用的man手册，了解在什么情况下该系统调用会出现挂死情况。另外，系统调用的参数也为我们提供了一些信息，例如挂死在如下系统调用：

read(16,
那我们可以知道read函数正在对文件描述符为16的文件或socket进行读取，进一步地，我们可以使用lsof工具，获取对应于文件描述符为16的文件名、该文件被哪些进程占用等信息。

 

小结

本文对Linux中常用的问题诊断工具strace进行了介绍，通过程序示例，介绍了strace的使用方法、输出格式以及使用strace分析程序挂死问题的方法，另外对strace工具的几个常用选项进行了说明，描述了这几个选项适用的场景。

下次再遇到程序挂死、命令执行报错的问题，如果从程序日志和系统日志中看不出问题出现的原因，先别急着google或找高手帮忙，别忘了一个强大的工具它就在那里，不离不弃，strace一下吧！