# 调试内核及模块 #

目前调试 Linux 内核与模块主要有 printk, /proc 和 kgdb 等方法，其中最常用的的 printk。

# 1. 调试方法 #
## 1.1 printk ##
printk 是调试内核代码时最常用的一种技术。在内核代码中的特定位置加入 printk() 调试调用，可以直接把所关心的信息打打印到屏幕上，从而可以观察程序的执行路径和所关心的变量、指针等信息。在使用 printk 时要注意优先级的问题。通过附加不同日志级别（loglevel），或者说消息优先级，可让 printk 根据这些级别所标示的严重程度，对消息进行分类。一般采用宏来指示日志级别。在头文件 <linux/kernel.h> 中定义了 8 种可用的日志级别字符串：KERN_EMERG，KERN_ALERT，KERN_CRIT，KERN_ERR，KERN_WARNING，KERN_NOTICE，KERN_INFO，KERN_INFO。共有 8 种优先级，用户可以根据需要进行配置，也可以通过 proc/sys/kernel/printk 动态修改设置。

使用 printk 来调试内核，明显的优点是：门槛低，上手快，定位问题有帮助。其缺点是要不断的加打印和重编内核。由于 syslogd 会一直保持对其输出文件的同步刷新，每打印一行都会引起一次磁盘操作，因此大量使用 printk 会严重降低系统性能。

日志级别一共有8个级别，printk的日志级别定义如下（在include/linux/kernel.h中）：

	#define KERN_EMERG 0/*紧急事件消息，系统崩溃之前提示，表示系统不可用*/
	#define KERN_ALERT 1/*报告消息，表示必须立即采取措施*/
	#define KERN_CRIT 2/*临界条件，通常涉及严重的硬件或软件操作失败*	/
	#define KERN_ERR 3/*错误条件，驱动程序常用KERN_ERR来报告硬件的错误*/
	#define KERN_WARNING 4/*警告条件，对可能出现问题的情况进行警告*/
	#define KERN_NOTICE 5/*正常但又重要的条件，用于提醒*/
	#define KERN_INFO 6/*提示信息，如驱动程序启动时，打印硬件信息*/
	#define KERN_DEBUG 7/*调试级别的消息*/

没有指定日志级别的printk语句默认采用的级别是：DEFAULT_ MESSAGE_LOGLEVEL（这个默认级别一般为<4>,即与KERN_WARNING在一个级别上），其定义在kernel/printk.c中可以找到。

内核可把消息打印到当前控制台上，可以指定控制台为字符模式的终端或打印机等。默认情况下，“控制台”就是当前的虚拟终端。

为了更好地控制不同级别的信息显示在控制台上，内核设置了控制台的日志级别console_loglevel。printk日志级别的作用是打印一定级别的消息，与之类似，控制台只显示一定级别的消息。

当日志级别小于console_loglevel时，消息才能显示出来。控制台相应的日志级别定义如下：

	#define MINIMUM_CONSOLE_LOGLEVEL　 1
	#define DEFAULT_CONSOLE_LOGLEVEL 　7 
	int console_printk[4] = {
		DEFAULT_CONSOLE_LOGLEVEL,
		DEFAULT_MESSAGE_LOGLEVEL,
		MINIMUM_CONSOLE_LOGLEVEL,
		DEFAULT_CONSOLE_LOGLEVEL,
	};
  
如果系统运行了klogd和syslogd，则无论console_loglevel为何值，内核消息都将追加到/var/log/messages中。如果klogd没有运行，消息不会传递到用户空间，只能查看/proc/kmsg。

变量console_loglevel的初始值是DEFAULT_CONSOLE_LOGLEVEL，可以通过sys_syslog系统调用进行修改。调用klogd时可以指定-c开关选项来修改这个变量。如果要修改它的当前值，必须先杀掉klogd，再加-c选项重新启动它。

通过读写/proc/sys/kernel/printk文件可读取和修改控制台的日志级别。查看这个文件的方法如下：

	#cat /proc/sys/kernel/printk
    	6   4   1   7
 
上面显示的4个数据分别对应控制台日志级别、默认的消息日志级别、最低的控制台日志级别和默认的控制台日志级别。

可用下面的命令设置当前日志级别：
 
	# echo 8 > /proc/sys/kernel/printk
	# echo 1 4 1 7 > /proc/sys/kernel/printk

这样所有级别<8,(0-7)的消息都可以显示在控制台上.

## 1.2 /proc 文件系统 ##
在 /proc 文件系统中，对虚拟文件的读写操作是一种与内核通信的手段。/proc 文件系统是一种特殊的、由程序创建的文件系统，内核使用它向外界输出信息。/proc 下面的每个文件都绑定于一个内核函数，这个函数在文件被读取时，动态地生成文件的“内容”。例如，/proc/modules 列出的是当前载入模块的列表。

## 1.3 kdb ##
kdb 是 Linux 内核的补丁，它提供了一种在系统能运行时对内核内存和数据结构进行检查的办法。kdb 还有许多其他的功能，包括单步调试（根据指令，而不是 C 源代码行），在数据访问中设置断点，反汇编代码，跟踪链表，访问寄存器数据等等。加上 kdb 补丁之后，在内核源码树的 Documentation/kdb 目录可以找到完整的手册页。
kdb 的优点是不需要两台机器进行调试。缺点是只能在汇编代码级进行调试。

## 1.4 gdb ##
gdb 全称是 GNU Debugger，是 GNU 开源组织发布的一个强大的 UNIX 下的程序调试工具。gdb 主要可帮助工程师完成下面 4 个方面的功能：

- 启动程序，可以按照工程师自定义的要求随心所欲的运行程序。
- 让被调试的程序在工程师指定的断点处停住，断点可以是条件表达式。
- 当程序被停住时，可以检查此时程序中所发生的事，并追索上文。
- 动态地改变程序的执行环境。

## 1.5 kgdb ##
kgdb 是一个在 Linux 内核上提供完整的 gdb 调试器功能的补丁，不过仅限于 x86 系统。它通过串口连线以钩子的形式挂入目标调试系统进行工作，而在远端运行 gdb。使用 kgdb 时需要两个系统——一个用于运行调试器，另一个用于运行待调试的内核（也可以是在同一台主机上用 vmware 软件运行两个操作系统来调试）。和 kdb 一样，kgdb 目前可从 oss.sgi.com 获得。

使用 kgdb 可以进行对内核的全面调试，甚至可以调试内核的中断处理程序。如果在一些图形化的开发工具的帮助下，对内核的调试将更方便。但是，使用 kgdb 作为内核调试环境最大的不足在于对 kgdb 硬件环境的要求较高，必须使用两台计算机分别作为 target 和 development 机。尽管使 用虚拟机的方法可以只用一台 PC 即能搭建调试环境，但是对系统其他方面的性能也提出了一定的要求，同时也增加了搭建调试环境时复杂程度。另外，kgdb 内 核的编译、配置也比较复杂，需要一定的技巧。当调试过程结束后时，还需要重新制作所要发布的内核。使用 kgdb 并不能 进行全程调试，也就是说 kgdb 并不能用于调试系统一开始的初始化引导过程。

## 1.6 oops ##
oops（也称 panic），称程序运行崩溃，程序崩溃后会产生 oops 消息。应用程序或内核线程的崩溃都会产生 oops 消息，通常发生 oops 时，系统不会发生死机，而在终端或日志中打印 oops 信息。

当使用 NULL 指针或不正确的指针值时，通常会引发一个 oops 消息，这是因为当引用一个非法指针时，页面映射机制无法将虚拟地址映像到物理地址，处理器就会向操作系统发出一个"页面失效"的信号。如果地址非法，内核就无法“换页”到并不存在的地址上；如果此时处理器处于超级用户模式，系统就会产生一个“oops”。

oops 显示发生错误时处理器的状态，包括 CPU 寄存器的内容、页描述符表的位置，以及其一些难理解的信息。这些消息由失效处理函数（arch/*/kernel/traps.c）中的 printk 语句产生。

用户处理 oops 消息的主要问题在于，我们很难从十六进制数值中看出什么内在的意义；为了使这些数据对程序员更有意义，需要把它们解析为符号。有两个工具可用来为开发人员完成这样的解析：klogd 和 ksymoops。前者只要运行就会自行进行符号解码；后者则需要用户有目的地调用。
下面讲述如何使用 gdb 在 KVM 虚拟机上调试内核和模块。本文采用的是 RedHat Enterprise Linux 7.0，在其他 Linux 创建 KVM 虚拟机的方法基本相似。

在Linux内核开发中的Oops是什么呢。当某些比较致命的问题出现时，我们的Linux内核也会抱歉的对我们说：“哎呦（Oops），对不起，我把事情搞砸了”。Linux内核在发生kernel panic时会打印出Oops信息，把目前的寄存器状态、堆栈内容、以及完整的Call trace都show给我们看，这样就可以帮助我们定位错误。

下面，我们来看一个实例。为了突出本文的主角--Oops，这个例子唯一的作用就是造一个空指针引用错误。
	
	#include <linux/kernel.h>
	#include <linux/module.h>
	static int __init hello_init(void)
	{
		int *p = 0;
		*p = 1;        
		return 0;
	}

 	static 	void __exit hello_exit(void)
	{
		return;
	}

	module_init(hello_init);
	module_exit(hello_exit);
	MODULE_LICENSE("GPL");

很明显，错误的地方就是第8行。接下来，我们把这个模块编译出来，再用insmod来插入到内核空间，正如我们预期的那样，Oops出现了。

	[  100.243737] BUG: unable to handle kernel NULL pointer dereference at (null)
	[  100.244985] IP: [<f82d2005>] hello_init+0x5/0x11 [hello]
	[  100.262266] *pde = 00000000 
	[  100.288395] Oops: 0002 [#1] SMP 
	[  100.305468] last sysfs file: /sys/devices/virtual/sound/timer/uevent
	[  100.325955] Modules linked in: hello(+)
	vmblock vsock vmmemctl vmhgfs acpiphp snd_ens1371 gameport snd_ac97_codec
	ac97_bus snd_pcm_oss snd_mixer_oss snd_pcm snd_seq_dummy snd_seq_oss
	snd_seq_midi snd_rawmidi snd_seq_midi_event snd_seq snd_timer snd_seq_device
	ppdev psmouse serio_raw fbcon tileblit font bitblit softcursor snd parport_pc
	soundcore snd_page_alloc vmci i2c_piix4 vga16fb vgastate intel_agp agpgart
	shpchp lp parport floppy pcnet32 mii mptspi mptscsih mptbase scsi_transport_spi
	vmxnet
 	[  100.472178] [ 100.494931] Pid: 1586, comm: insmod Not tainted (2.6.32-21-generic #32-Ubuntu) VMware Virtual Platform
	[  100.540018] EIP: 0060:[<f82d2005>] EFLAGS: 00010246 CPU: 0
	[  100.562844] EIP is at hello_init+0x5/0x11 [hello]
	[  100.584351] EAX: 00000000 EBX: fffffffc ECX: f82cf040 EDX: 00000001
	[  100.609358] ESI: f82cf040 EDI: 00000000 EBP: f1b9ff5c ESP: f1b9ff5c
	[  100.631467] DS: 007b ES: 007b FS: 00d8 GS: 00e0 SS: 0068
	[  100.657664] Process insmod (pid: 1586,ti=f1b9e000 task=f137b340 task.ti=f1b9e000)
	[  100.706083] Stack: 
	[  100.731783] f1b9ff88 c0101131 f82cf040 c076d240 fffffffc f82cf040 0072cff4 f82d2000
	[  100.759324] <0> fffffffc f82cf040 0072cff4 f1b9ffac c0182340 f19638f8 f137b340 f19638c0
	[  100.811396] <0> 00000004 09cc9018 09cc9018 00020000 f1b9e000 c01033ec 09cc9018 00015324
	[  100.891922] Call Trace:
	[  100.916257] [<c0101131>] ? do_one_initcall+0x31/0x190
	[  100.943670] [<f82d2000>] ? hello_init+0x0/0x11 [hello]
	[  100.970905] [<c0182340>] ? sys_init_module+0xb0/0x210
	[  100.995542] [<c01033ec>] ? syscall_call+0x7/0xb
	[  101.024087] Code: <c7> 05 00 00 00 00 01 00 00 00 5d c3 00 00 00 00 00 00 00 00 00 00 
 	[  101.079592] EIP: [<f82d2005>] hello_init+0x5/0x11 [hello] SS:ESP 0068:f1b9ff5c
	[  101.134682] CR2: 0000000000000000
	[  101.158929] ---[ end trace e294b69a66d752cb]---

Oops首先描述了这是一个什么样的bug，然后指出了发生bug的位置，即“IP: [<f82d2005>] hello_init+0x5/0x11 [hello]”。

在这里，我们需要用到一个辅助工具objdump来帮助分析问题。objdump可以用来反汇编，命令格式如下：

	objdump -S  hello.o

下面是hello.o反汇编的结果，而且是和C代码混排的，非常的直观。

	hello.o:     file format elf32-i386
	Disassembly of section .init.text:
	00000000 <init_module>:
	#include <linux/kernel.h>
	#include <linux/module.h>
	static int __init hello_init(void)
	{
	0:        55                  
	        push   %ebp
		int *p = 0;
		*p = 1;
		return 0;
	}

  
	1:        31 c0               
        xor    %eax,%eax

	#include <linux/kernel.h>
	#include <linux/module.h>
	static int __init hello_init(void)
	{
	3:        89 e5               
        mov    %esp,%ebp

		int *p = 0;
		*p = 1;
 
	5:        c7 05 00 00 00 00 01
        movl   $0x1,0x0

	c:        00 00 00 
		return 0;
	}


我们再回过头来检查一下上面的Oops，看看Linux内核还有没有给我们留下其他的有用信息。

Oops:
0002 [#1]

这里面，0002表示Oops的错误代码（写错误，发生在内核空间），#1表示这个错误发生一次。

Oops的错误代码根据错误的原因会有不同的定义，本文中的例子可以参考下面的定义（如果发现自己遇到的Oops和下面无法对应的话，最好去内核代码里查找）：

 * error_code:

 *  bit 0 == 0 means no page found, 1 means protection fault

 *  bit 1 == 0 means read, 1 means write

 *  bit 2 == 0 means kernel, 1 means user-mode

 *  bit 3 == 0 means data, 1 means instruction

有时候，Oops还会打印出Tainted信息。这个信息用来指出内核是因何种原因被tainted（直译为“玷污”）。具体的定义如下：

  1: 'G' if all modules loaded have a GPL or
compatible license, 'P' if any proprietary module has been loaded.  Modules without a MODULE_LICENSE or with a
MODULE_LICENSE that is not recognised by insmod as GPL compatible are assumed
to be proprietary.

  2: 'F' if any module was force loaded by
"insmod -f", ' ' if all modules were loaded normally.

  3: 'S' if the oops occurred on an SMP kernel
running on hardware that hasn't been certified as safe to run multiprocessor.
Currently this occurs only on various Athlons that are not SMP capable.

  4: 'R' if a module was force unloaded by
"rmmod -f", ' ' if all modules were unloaded normally.

  5: 'M' if any processor has reported a
Machine Check Exception, ' ' if no Machine Check Exceptions have occurred.

  6: 'B' if a page-release function has found a
bad page reference or some unexpected page flags.

  7: 'U' if a user or user application
specifically requested that the Tainted flag be set, ' ' otherwise.

  8: 'D' if the kernel has died recently, i.e.
there was an OOPS or BUG.

  9: 'A' if the ACPI table has been overridden.

 10: 'W' if a warning has previously been
issued by the kernel. (Though some warnings may set more specific taint flags.)

 11: 'C' if a staging driver has been loaded.

 12: 'I' if the kernel is working around a
severe bug in the platform firmware (BIOS or similar). 

基本上，这个Tainted信息是留给内核开发者看的。用户在使用Linux的过程中如果遇到Oops，可以把Oops的内容发送给内核开发者去debug，内核开发者根据这个Tainted信息大概可以判断出kernel panic时内核运行的环境。如果我们只是debug自己的驱动，这个信息就没什么意义了。

本文的这个例子非常简单，Oops发生以后没有造成宕机，这样我们就可以从dmesg中查看到完整的信息。但更多的情况是Oops发生的同时系统也会宕机，此时这些出错信息是来不及存入文件中的，关掉电源后就无法再看到了。我们只能通过其他的方式来记录：手抄或者拍照。

还有更坏的情况，如果Oops信息过多的话，一页屏幕显示不全，我们怎么来查看完整的内容呢？第一种方法，在grub里用vga参数指定更高的分辨率以使屏幕可以显示更多的内容。很明显，这个方法其实解决不了太多的问题；第二种方法，使用两台机器，把调试机的Oops信息通过串口打印到宿主机的屏幕上。但现在大部分的笔记本电脑是没有串口的，这个解决方法也有很大的局限性；第三种方法，使用内核转储工具kdump把发生Oops时的内存和CPU寄存器的内容dump到一个文件里，之后我们再用gdb来分析问题。

开发内核驱动的过程中可能遇到的问题是千奇百怪的，调试的方法也是多种多样，Oops是Linux内核给我们的提示，我们要用好它。

# 2. gdb 调试内核 #
## 2.1 安装 Linux 系统并编译内核 ##

使用 gdb 调试需要系统内核中包含调试信息，所以我们从头开始编译内核。本文以内核版本 3.18.2 为例。
首先要下载内核源码。内核源码的下载地址为：http://www.kernel.org

	# tar -zxvf linux-version.tar.gz

修改 Makefile, 将 “-O3” 改为 “-O1"，这样编译出的内核包含调试信息并正确的被 gdb 调试：

	ifdef CONFIG_CC_OPTIMIZE_FOR_SIZE
	KBUILD_CFLAGS += -O0 $(call cc-disable-warning,maybe-uninitialized,)
	else
	KBUILD_CFLAGS += -O1 -g
	endif 

清除旧的编译信息

	make mrproper

配置内核：

	make menuconfig .config(kgdb(kernel haking), module load)

编译内核

	make j32
	make modules_install(/lib/modules/3.18.2)
	make install

重启 linux

	reboot

## 2.2 创建支持 gdb 调试的 KVM 虚拟机 ##
本节介绍如何在 Linux RedHat/CentOS 上创建 KVM 虚拟机，并配置虚机使其运行 gdbserver 以支持 gdb 调试。
如果 KVM 没有安装，首先安装 KVM 及相关软件。安装步骤如下：
KVM 需要有 CPU 的支持（Intel vmx 或 AMD svm），在安装 KVM 之前检查一下 CPU 是否提供了虚拟技术的支持：
[root@myKVM ~]# egrep '^flags.*(vmx|svm)' /proc/cpuinfo
若有显示，则说明处理器具有 VT 功能。
在主板 BIOS 中开启 CPU 的 Virtual Technolege(VT，虚化技术 )；
安装 kvm 及其需要的软件包。


	[root@myKVM ~]# yum groupinstall KVM

检查 kvm 模块是否安装，使用以下命令显示两个模块则表示安装完成：

	[root@myKVM ~]# lsmod | grep kvm 
	 kvm_intel              52570  0 
	 kvm                   314739  1 kvm_intel

启动 virt-manager 管理界面。
客户端：使用 VNC 连接到服务器端，因为需要用服务器的图形界面。
服务器端：启动 libvirtd 服务，并保证下次自动启动：

	[root@myKVM ~]# service libvirtd start 
	 Starting libvirtd daemon:                                  [ 确定 ] 
	[root@myKVM ~]# chkconfig libvirtd on

接下来远程创建和管理 KVM 虚拟机。打开 Application -> System Tools -> Virtual Machine Manager 就可以装虚拟机了，功能跟 VMware 类似。
相关的命令有 virt-manager 和 virsh。
使用“virsh list”可以查看虚拟机是否已经创建，然后通过“virsh edit <vm_name>”可以修改 VM 配置。
根据本文的测试结果，domain type 必须改为 .../qemu/1.0 才能支持 gdb 调试。

	<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>

然后添加下面的配置使得虚拟机支持 gdb 调试：

	<qemu:commandline> 
	    <qemu:arg value='-S'/> 
	    <qemu:arg value='-gdb'/> 
	    <qemu:arg value='tcp::1234'/> 
	 </qemu:commandline>

如果创建好的虚拟机不能访问，可以使用 ping, brctl show, ps 等命令进行诊断，不再一一详述。

## 2.3 使用 gdb 调试 KVM 虚拟机的内核与模块 ##
本节介绍如何调试 KVM 虚拟机内核和模块。并说明在调试过程中如何加载模块并链接符号表。
首先将虚拟机更新至编译好的内核。可将 vmlinux , System.map, initramfs, /lib/modules/<kernel version> 这些文件拷贝至虚拟机，或者在虚拟机上重新编译内核。
然后在主机端创建一个目录，拷贝 vmlinux 文件并进入 gdb 调试：

	gdb vmlinux-3.18.2

连接虚拟机：
	target remote 127.0.0.1:1234

此时虚拟机已经被中断。
下面在 load_module 添加断点并继续执行。

在虚拟机上插入需要调试的模块：

	insmod nzuta.ko

在宿主机上找到调用 do_init_module 的地方，添加断点并执行到此处。

下面是关键的部分。
打印 text section，data section 和 bss section 的名称和地址：

	print mod->sect_attrs->attrs[1]->name 
	print mod->sect_attrs->attrs[7]->name 
	print mod->sect_attrs->attrs[9]->name 
	print /x mod->sect_attrs->attrs[1]->address 
	print /x mod->sect_attrs->attrs[7]->address 
	print /x mod->sect_attrs->attrs[9]->address

根据上面打印的地址导入编译好的内核模块（注意编译此模块需要使用与虚拟机相同的内核源码编译，也需要使用 -O1 选项）：

	add-symbol-file /home/dawei/nzuta/nzuta.ko <text addr> -s .data <data addr> -s .bss 
 		<bss addr>


下面就可以在模块代码中添加断点并单步调试了：

如果要退出 gdb，需要先使用 delete 命令清理所有断点，并 detach。


# 参考资料 #

内核调试神器SystemTap
