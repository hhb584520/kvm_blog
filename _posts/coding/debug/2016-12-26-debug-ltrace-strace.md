
# 1. ltrace 和 strace 介绍 #

我们在内核调试的时候，经常想跟踪一下某一个进程的库函数调用或者跟踪每个进程的系统调用，这个时候我们就用到strace和ltrace。 ltrace能够跟踪进程的库函数调用,它会显现出哪个库函数被调用,而strace则是跟踪进程的每个系统调用.

其中它们共同最常用的三个命令行参数是：
 
	-f 除了跟踪当前进程外，还跟踪其子进程
	-o file 将输出信息写到文件file中，而不是显示到标准错误输出（stderr）
	-p PID 绑定到一个由PID对应的正在运行的进程，此参数常用来调试后台进程（守护进程）
 
注意：strace的输出为标准错误输出，因此可以像下面这样将显示内容输出到标准输出上，通过管道再传给grep、less等。

	$ strace ./st1 2>&1| grep open  

PS:

- 2>&1     将标准出错重定向到标准输出
- 2>          代表错误重定向
- &1         代表标准输出

## 1.1 ltrace 使用 ##
下面我们还是用最简单的helloworld说明问题：

	#include <stdio.h>
	
	int	main ()
	{
	    printf("Hello world!\n");
	    return 0;
	}

编译：

	gcc hello.c -o hello


用ltrace跟踪hello程序,如下:

	ltrace ./hello
 
	__libc_start_main(0x80483b4, 1, 0xbfeab574, 0x80483e0, 0x80483d0 <unfinished ...>
	puts("Hello World"Hello World
	)                              = 12
	+++ exited (status 0) +++

这里我们注意到puts()库函数打印出字符串。puts()这个函数在内核arch/arm/boot/compressed/head.S有实现，另外，puts()这个函数在uboot代码中也有实现，我们的printf，print都是靠puts函数去实现输出的，大家可以看一下。

 
## 1.2 strace 使用 ##

如何使用strace对程序进行跟踪，如何查看相应的输出？下面我们通过一个例子来说明。

### 1.2.1 简单程序例子 ###
**被跟踪程序示例**

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

以上程序尝试以只读的方式打开/tmp/foo文件，然后退出，其中只使用了open这一个系统调用函数。之后我们对该程序进行编译，生成可执行文件：

	lx@LX:~$ gcc main.c -o main
 

**strace跟踪输出**

使用以下命令，我们将使用strace对以上程序进行跟踪，并将结果重定向至main.strace文件：

	lx@LX:~$ strace -o main.strace ./main
接下来我们来看main.strace文件的内容：

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

Line12:  调用read，从/lib/i386-linux-gnu/libc.so.6该libc库文件中读取512bytes，即读取ELF头信息。Linux系统默认分配了3个文件描述符值：0－ standard input，1－standard output，2－standard error

Line15:  使用mprotect函数对0x6c7000起始的4096bytes空间进行保护(PROT_NONE表示不能访问，PROT_READ表示可以读取)

Line24:  调用munmap函数，将/etc/ld.so.cache文件从内存中去映射，与Line 8的mmap2对应

Line25:  对应源码中使用到的唯一的系统调用——open函数，使用其打开/tmp/foo文件

Line26:  子进程结束，退出码为5(为什么退出值为5？返回前面程序示例部分看看源码吧：)

 

**输出分析**

从上面输出可以发现，真正能与源码对应上的只有open这一个系统调用(Line25)，其他系统调用几乎都用于进行进程初始化工作：装载被执行程序、载入libc函数库、设置内存映射等。

源码中的if语句或其他代码在相应strace输出中并没有体现，因为它们并没有唤起系统调用。strace只关心程序与系统之间产生的交互，因而strace不适用于程序逻辑代码的排错和分析。

对于Linux中几百个系统调用，上面strace输出的几个只是冰山一角，想要更深入地了解Linux系统调用，那就man一下吧！

man 2 系统调用名称
man ld.so  //Linux动态链接的manpage

## 1.2.2 跟踪子进程 ###

默认情况下，strace只跟踪指定的进程，而不对指定进程中新建的子进程进行跟踪。使用-f选项，可对进程中新建的子进程进行跟踪，并在输出结果中打印相应进程PID：

	mprotect(0x5b1000, 4096, PROT_READ)     = 0
	munmap(0xb77fc000, 80682)               = 0
	clone(Process 13600 attached
	child_stack=0, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0xb77fb938) = 13600
	[pid 13599] fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
	[pid 13600] fstat64(1, {st_mode=S_IFCHR|0620, st_rdev=makedev(136, 0), ...}) = 0
	[pid 13599] mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0 <unfinished ...>
	[pid 13600] mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0xb780f000
	……

对多进程程序、命令和脚本使用strace进行跟踪的时，一般打开-f选项。 

**记录系统调用时间**

strace还可以记录程序与系统交互时，各个系统调用发生时的时间信息，有r、t、tt、ttt、T等几个选项，它们记录时间的方式为：

	-T:   记录各个系统调用花费的时间，精确到微秒
	-r:   以第一个系统调用(通常为execve)计时，精确到微秒
	-t:   时：分：秒
	-tt:  时：分：秒 . 微秒
	-ttt: 计算机纪元以来的秒数 . 微秒

比较常用的为T选项，因为其提供了每个系统调用花费时间。而其他选项的时间记录既包含系统调用时间，又算上用户级代码执行用时，参考意义就小一些。对部分时间选项我们可以组合起来使用，例如：

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

最左边一列为-r选项对应的时间输出，最右边一列为-T选项对应的输出。

### 1.2.3 跟踪正在运行的进程 ###

使用strace对运行中的程序进行跟踪，使用命令“strace -p PID”即可，命令执行之后，被跟踪的进程照常执行，strace的其他选项也适用于运行中的进程跟踪。使用strace处理程序挂死。最后我们通过一个程序示例，学习使用strace分析程序挂死的方法。

**挂死程序源码**

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

查看进程 ID

	# ps ux | grep hang

可向该程序传送user和system参数，以上代码使用死循环模拟用户态挂死，调用sleep模拟内核态程序挂死。

$ strace -p `pidof hang`  

**strace跟踪输出**

用户态挂死跟踪输出：

lx@LX:~$ gcc hang.c -o hang
lx@LX:~$ strace ./hang user
……
mprotect(0x8049000, 4096, PROT_READ)    = 0
mprotect(0xb59000, 4096, PROT_READ)     = 0
munmap(0xb77bf000, 80682)               = 0
getpid()                                = 14539

内核态挂死跟踪输出：


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

**输出分析**

用户态挂死情况下，strace在getpid()一行输出之后没有其他系统调用输出；进程在内核态挂死，最后一行的系统调用nanosleep不能完整显示，这里nanosleep没有返回值表示该调用尚未完成。

因而我们可以得出以下结论：使用strace跟踪挂死程序，如果最后一行系统调用显示完整，程序在逻辑代码处挂死；如果最后一行系统调用显示不完整，程序在该系统调用处挂死。

当程序挂死在系统调用处，我们可以查看相应系统调用的man手册，了解在什么情况下该系统调用会出现挂死情况。另外，系统调用的参数也为我们提供了一些信息，例如挂死在如下系统调用：

read(16,
那我们可以知道read函数正在对文件描述符为16的文件或socket进行读取，进一步地，我们可以使用lsof工具，获取对应于文件描述符为16的文件名、该文件被哪些进程占用等信息。


### 1.2.4 显示指定跟踪的系统调用 ###

-e expr    
A qualifying expression which modifieswhich events to trace or how to trace them. The format of the expression is:
[qualifier=][!]value1[,value2]...
where qualifier is one of trace, abbrev,verbose, raw, signal, read, or write and value is  a qualifier-dependent symbol or number. The default qualifier is trace. Using an exclamation mark negates the set of values.  For example, -eopen means literally -etrace=open which in turn means trace only the open system call. By contrast,-etrace=!open means to trace every system call except open.  In addition, the special values all and nonehave the obvious meanings.
Note that some shells use the exclamationpoint for history expansion even inside quoted arguments. If so, you mustescape the exclamation point with a backslash.

例如：

(1) 只记录open的系统调用
 
	$ strace -e trace=open ./st1  
	open("/etc/ld.so.cache", O_RDONLY)      = 3  
	open("/lib/libc.so.6", O_RDONLY)        = 3  
	open("/etc/shadow", O_RDONLY)           = -1 EACCES (Permission denied)  
	Error!  
	open("/etc/shadow", O_RDONLY)           = -1 EACCES (Permission denied)  
	Error!  

(2) 另外：

-e trace=all              跟踪进程的所有系统调用

-e trace=network    只记录和网络api相关的系统调用

-e trace=file             只记录涉及到文件名的系统调用

-e trace=desc         只记录涉及到文件句柄的系统调用

其他的还包括：process,ipc, signal等。


### 1.2.5 指定系统调用参数的长度 ###


显示系统调用参数时，对于字符串显示的长度， 默认是32，如果字符串参数很长，很多信息显示不出来。

-s strsize  
Specify the maximum string size to print(the default is 32). Note that filenames are not considered strings and arealways printed in full.

例如：

strace -s 1024 ./st1


### 1.2.6 用strace了解程序的工作原理 ###

问题：在进程内打开一个文件，都有唯一一个文件描述符（fd: file descriptor）与这个文件对应。如果已知一个fd，如何获取这个fd所对应文件的完整路径？不管是Linux、FreeBSD或其他Unix系统都没有提供这样的API，那怎么办呢？

我们换个角度思考：Unix下有没有什么命令可以获取进程打开了哪些文件？使用 lsof 命令即可以知道程序打开了哪些文件，也可以了解一个文件被哪个进程打开。（平时工作中很常用，例如，使用 lsof -p PID来查找某个进程存放的位置）
 
	#include<stdio.h>   
	#include<unistd.h>   
	#include<sys/types.h>   
	#include<sys/stat.h>   
	#include<fcntl.h>   
	  
	int main()  
	{  
	    open("wcdj", O_CREAT|O_RDONLY);// open file foo   
	    sleep(1200);// sleep 20 mins 方便调试   
	  
	    return 0;  
	}  

	/* 
	gcc -Wall -g -o testlsof testlsof.c  
	./testlsof &                                       
	*/  
  
	$ gcc -Wall -g -o testlsof testlsof.c            
	$ ./testlsof &  
	[1] 12371  
	$ strace -o lsof.strace lsof -p 12371  
	COMMAND    PID      USER   FD   TYPE DEVICE    SIZE    NODE NAME  
	testlsof 12371 gerryyang  cwd    DIR    8,4    4096 2359314 /data/home/gerryyang/test/HACK  
	testlsof 12371 gerryyang  rtd    DIR    8,1    4096       2 /  
	testlsof 12371 gerryyang  txt    REG    8,4    7739 2359364 /data/home/gerryyang/test/HACK/testlsof  
	testlsof 12371 gerryyang  mem    REG    8,1 1548470 1117263 /lib/libc-2.4.so  
	testlsof 12371 gerryyang  mem    REG    8,1  129040 1117255 /lib/ld-2.4.so  
	testlsof 12371 gerryyang  mem    REG    0,0               0 [stack] (stat: No such file or directory)  
	testlsof 12371 gerryyang    0u   CHR  136,0               2 /dev/pts/0  
	testlsof 12371 gerryyang    1u   CHR  136,0               2 /dev/pts/0  
	testlsof 12371 gerryyang    2u   CHR  136,0               2 /dev/pts/0  
	testlsof 12371 gerryyang    3r   REG    8,4       0 2359367 /data/home/gerryyang/test/HACK/wcdj  

	$ grep "wcdj" lsof.strace   
	readlink("/proc/12371/fd/3", "/data/home/gerryyang/test/HACK/wcdj", 4096) = 35  
	$ cd /proc/12371/fd  
	$ ls -l  
	总计 4  
	lrwx------ 1 gerryyang users 64 2012-03-23 14:14 0 -> /dev/pts/0  
	lrwx------ 1 gerryyang users 64 2012-03-23 14:14 1 -> /dev/pts/0  
	lrwx------ 1 gerryyang users 64 2012-03-23 14:14 2 -> /dev/pts/0  
	lr-x------ 1 gerryyang users 64 2012-03-23 14:14 3 -> /data/home/gerryyang/test/HACK/wcdj  

用strace跟踪lsof的运行，输出结果保存在lsof.strace中。然后通过对lsof.strace内容的分析
从而了解到其实现原理是：
lsof利用了/proc/pid/fd目录。Linux内核会为每一个进程在/proc建立一个以其pid为名的目录用来保存进程的相关信息，而其子目录fd保存的是该进程打开的所有文件的fd。进入/proc/pid/fd目录下，发现每一个fd文件都是符号链接，而此链接就指向被该进程打开的一个文件。我们只要用readlink()系统调用就可以获取某个fd对应的文件了。

# 2. 交叉编译 strace #

strace是一款非常强大的调试用户程序的工具，如在嵌入式平台使用，则需要对其进行交叉编译；以ARM及PPC平台为例，编译strace-4.5.18；

## 2.1 下载解压 ##

1.下载 strace

 strace-4.5.16.tar.bz2，不要下载最新的strace-4.5.18.tar.bz2，因为后者编译会出错。下载网址是：http://sourceforge.net/project/showfiles.php?group_id=2861&package_id=2819；

2.解压。对于ARM平台，必须打上一个补丁，补丁下面；

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
	* 

## 2.2 选择平台 ##

- ARM平台(arm-linux-gcc)

	CC=arm-linux-gcc LD=arm-linux-ld RANLIB=arm-linux-ranlib ./configure --host=arm-linux --target=arm-linux

- PPC平台(ppc-linux-)

	CC=ppc_82xx-gcc LD=ppc_82xx-ld RANLIB=ppc_82xx-ranlib ./configure --host=powerpc-linux --target=powerpc-linux

- DaVinCi平台(arm_v5t_le-gcc)
	CC=arm_v5t_le-gcc LD=arm_v5t_le-ld RANLIB=arm_v5t_le-ranlib ./configure --host=arm-linux --target=arm-linux

## 2.3 编译 ##

	./configure --host=arm-linux CC=arm_v5t_le-gcc LD=arm_v5t_le-ld；
    make && make check

	make CFLAGS+="-static",生成strace静态可执行文件，2M多；
	strip。arm_v5t_le-stip strace，这样可执行文件就减小到600多K。

以上采用的是达芬奇平台的arm工具，也可以直接使用通用的arm-linux-gcc工具，版本3.4.1的我试过，可以编译通过，其他版本的不清楚。
如果希望安装到指定目录，则在配置时指定 --prefix=/yourdir，编译之后执行make install即可。

# 3. strace 高级使用 #
## 3.1 一个分析示例 ##
我们可以先通过 top 找到 CPU 占用高的进程

在本例中大家很容易发现 CPU 主要是被若干个 PHP 进程占用了，同时 PHP 进程占用的比较多的内存，不过系统内存尚有结余，SWAP 也不严重，这并不是问题主因。

不过在 CPU 列表中能看到 CPU 主要消耗在内核态「sy」，而不是用户态「us」，和我们的经验不符。Linux 操作系统有很多用来跟踪程序行为的工具，内核态的函数调用跟踪用「strace」，用户态的函数调用跟踪用「ltrace」，所以这里我们应该用「strace」：

	shell> strace -p <PID>

不过如果直接用 strace 跟踪某个进程的话，那么等待你的往往是满屏翻滚的字符，想从这里看出问题的症结并不是一件容易的事情，好在 strace 可以按操作汇总时间：

	shell> strace -cp <PID>

通过「c」选项用来汇总各个操作的总耗时，运行后的结果大概如下图所示：

	strace -cp
很明显，我们能看到 CPU 主要被 clone 操作消耗了，还可以单独跟踪一下 clone：

	shell> strace -T -e clone -p <PID>
通过「T」选项可以获取操作实际消耗的时间，通过「e」选项可以跟踪某个操作：

	strace -T -e clone -p
很明显，一个 clone 操作需要几百毫秒，至于 clone 的含义，参考 man 文档：

clone() creates a new process, in a manner similar to fork(2). It is actually a library function layered on top of the underlying clone() system call, hereinafter referred to as sys_clone. A description of sys_clone is given towards the end of this page.

Unlike fork(2), these calls allow the child process to share parts of its execution context with the calling process, such as the memory space, the table of file descriptors, and the table of signal handlers. (Note that on this manual page, “calling process” normally corresponds to “parent process”. But see the description of CLONE_PARENT below.)

简单来说，就是创建一个新进程。那么在 PHP 里什么时候会出现此类系统调用呢？查询业务代码看到了 exec 函数，通过如下命令验证它确实会导致 clone 系统调用：

	shell> strace -eclone php -r 'exec("ls");'

# 参考资料 #
strace的使用介绍可以参考以下两篇文章：

1.http://www.ibm.com/developerworks/cn/aix/library/au-unix-strace.html。

2.http://blog.chinaunix.net/u1/38279/showart_367248.html