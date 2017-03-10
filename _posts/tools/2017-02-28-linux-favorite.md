## 1. 查看系统是64位还是32位 ##
1、getconf LONG_BIT or getconf WORD_BIT
2、file /bin/ls
3、lsb_release -a

## 2. 查看Linux的内核版本 ##

cat /proc/version 

## 3. 查看Linux的发行版 ##
登录到服务器执行 lsb_release -a ,即可列出所有版本信息,例如:
   [root@3.5.5Biz-46 ~]# [root@q1test01 ~]# lsb_release -a
   LSB Version:    :core-3.0-amd64:core-3.0-ia32:core-3.0-noarch:graphics-3.0-amd64:graphics-3.0-
   ia32:graphics-3.0-noarch
   Distributor ID: RedHatEnterpriseAS
   Description:    Red Hat Enterprise Linux AS release 4 (Nahant Update 2)
   Release:        4
   Codename:       NahantUpdate2
   注:这个命令适用于所有的linux，包括Redhat、SuSE、Debian等发行版。

## 4. 安装 自己编译 Driver ##
下面以 sgx driver 为例
git clone https://github.com/01org/linux-sgx-driver.git

### for redhat

Build the Intel(R) SGX Driver

To build Intel SGX driver, change the directory to the driver path and enter the following command:

	$ make
You can find the driver isgx.ko generated in the same directory.

Install the Intel(R) SGX Driver

To install the Intel SGX driver, enter the following command with root privilege:

	$ sudo mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"    
	$ sudo cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"    
	$ sudo /sbin/depmod
	$ sudo /sbin/modprobe isgx

Uninstall the Intel(R) SGX Driver

Before uninstall the Intel SGX driver, make sure the aesmd service is stopped. See the topic, Start or Stop aesmd Service, on how to stop the aesmd service.
To uninstall the Intel SGX driver, enter the following commands:

	$ sudo /sbin/modprobe -r isgx
	$ sudo rm -rf "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
	$ sudo /sbin/depmod
	$ sudo /bin/sed -i '/^isgx$/d' /etc/modules

### for ubuntu

Build the Intel(R) SGX Driver

To build Intel SGX driver, change the directory to the driver path and enter the following command:

	$ make
You can find the driver isgx.ko generated in the same directory.

Install the Intel(R) SGX Driver

To install the Intel SGX driver, enter the following command with root privilege:

	$ sudo mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"    
	$ sudo cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"    
	$ sudo sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"    
	$ sudo /sbin/depmod
	$ sudo /sbin/modprobe isgx

Uninstall the Intel(R) SGX Driver

Before uninstall the Intel SGX driver, make sure the aesmd service is stopped. See the topic, Start or Stop aesmd Service, on how to stop the aesmd service.
To uninstall the Intel SGX driver, enter the following commands:

	$ sudo /sbin/modprobe -r isgx
	$ sudo rm -rf "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
	$ sudo /sbin/depmod
	$ sudo /bin/sed -i '/^isgx$/d' /etc/modules


## 6. 提取ISO 文件夹里面的文件

	mkdir /mnt/iso  
	mount -o loop *.iso /mnt/iso
	ls /mnt/iso

## 7. 修改时区和时间
**时区**

查看当前时区
	date -R

修改设置时区
    方法(1)：tzselect  
    方法(2)：timeconfig //仅限于RedHat Linux 和 CentOS            
    方法(3)：dpkg-reconfigure tzdata //适用于Debian
            
复制相应的时区文件，替换系统时区文件；或者创建链接文件

	cp /usr/share/zoneinfo/$主时区/$次时区 /etc/localtime

在中国可以使用：

	cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

**时间**

查看时间和日期

    date

设置时间和日期

    将系统日期设定成1996年6月10日的命令
    date -s 06/22/96

    将系统时间设定成下午1点52分0秒的命令
    date -s 13:52:00 

将当前时间和日期写入BIOS，避免重启后失效

    hwclock -w


## 8. 强制 Umount NFS ##
当Umount一个目录时，提示device is busy，umount加参数f，是强制执行umount，但是许多时候均不会成功。 原理上要想umount，首先要kill正在使用这个目录的进程。假设无法卸载的设备为/dev/sdb1 

1)运行下面命令看一下哪个用户哪个进程占用着此设备  

	fuser -m -v /dev/sdb1

2)运行下面命令杀掉占用此设备的进程 

	fuser -m -v -k /dev/sdb1 
	或者fuser -m -v -k -i  /dev/sdb1(每杀掉一下进程会让你确认） 

3)再umount

*杀掉所有以任何形式访问文件系统 /dev/sdb1的进程： 
$fuser -km /dev/sdb1 
这个办法是一个比较粗鲁的办法，通常适用于在测试等非正式环境。比较正规的要配合ps等命令，查出使用的用户、进程、命令等，然后做出综合判断，必要时先通知(signal或口头等)用户，确认安全时才可以强制kill此进程。 
但有时fuser执行时，仍然会有报错，其实umount强制退出，可以考虑用参数l（Lazy），这个参数是比f(Force)更强大的终极命令。 
Man Umount 查看f和l的参数说明如下： 
-f     Force  unmount.  This  allows  an  NFS-mounted  filesystem  to be unmounted if the NFS server is unreachable. Note: when using umount -f on an NFS filesystem, the filesystem must be mounted using either the soft, or intr options (see nfs(5).  This option  will  not  force  unmount  a  <A1><AE>busy<A1><AF>  filesystem  (use  -l instead). (Requires kernel 2.1.116 or later.)
-l     Lazy unmount. Detach the filesystem from the filesystem hierarchy now, and cleanup all references to the filesystem as soon as it is not busy anymore. This option allows a <A1><AE>busy<A1><AF> filesystem to be unmounted.  (Requires kernel 2.4.11 or later.) 

## 9. udev 介绍 ##
http://www.ibm.com/developerworks/cn/linux/l-cn-udev/index.html?ca=drs-cn-0304

## 10. 网卡命名机制 ##
1.传统命名：以太网eth[0,1,2,...],wlan[0,1,2,...]
2.udev支持多种不同的命名方案：UDEV是系统在用户空间探测内核空间，通过sys接口所输出的硬件设备，并配置的硬件设备的一种应用程序，在centos7上UDEV支持多种不同的命名方案，无非就是支持基于固件的命名（firmware,基于主板上rom芯片）或者是通过总线拓扑（PCI总线）结构来命名。总线拓扑（PCI总线）结构命名主要是根据对应设备所在的位置来命名，slot设备上的第几个接口方式命名，这样命名的方式就是能够实现自动命名，只要接口不坏，无论是哪一块网卡插上去其名称一定是固定的。
名称组成格式：  

- en: ethernet  
- wl: wlan(无线网卡）  
- ww: wwan（广域网拨号）  

名称类型：  

- o<index>: 集成设备的设备索引号(基于主板上rom芯片)；
- s<slot>: PCI-E扩展槽的索引号
- x<MAC>: 基于MAC地址的命名；
- p<bus>s<slot>:enp2s1

## 11.常用工具大全--nice ##

http://linuxtools-rst.readthedocs.io/zh_CN/latest/index.html  

http://www.computerhope.com/jargon/m/mkdir.htm

## 12.lspci ##
lspci -Dn -s $bdf  
-D 选项表示在输出信息中显示设备的 domain  
-n 选项表示用数字的方式显示设备的 vendor ID 和 device ID  
-s 选项表示仅显示后面指定的一个设备的信息  

lspci -k -s $bdf  
-k 表示输出信息中显示正在使用的驱动和内核中可以支持该设备的模板。

lspci -v -s $bdf | grep SR-IOV  
查看PCI设备是否支持 SR-IOV 功能

## 13.时间格式 ##

date -d yesterday +%Y%m%d

## 14.创建用户 ##

	useradd -s /bin/sh -g group –G adm,root -d /usr/sam/ -m gem

此命令新建了一个用户gem，该用户的登录Shell是/bin/sh，它属于group用户组，同时又属于adm和root用户组，其中group用户组是其主组。其中-d和-m选项用来为登录名sam产生一个主目录/usr/sam（/usr为默认的用户主目录所在的父目录）。

## 15.同步时间 ##
    ntpdate vt-master 

## 16.统计某个文件夹下面的代码行数 ##

	wc -l `find -name *.c`

## 17.压缩和解压文件

### 解压 xz 格式文件 ###
方法一：
需要用到两步命令，首先利用 xz-utils 的 xz 命令将 linux-3.12.tar.xz 解压为 linux-3.12.tar，其次用 tar 命令将 linux-3.12.tar 完全解压。

xz -d linux-3.12.tar.xz
tar -xf linux-3.12.tar

方法二（推荐）

tar -Jxf linux-3.12.tar.xz

### 创建 xz 格式文件 ###
方法一：
也是用到两步命令，首先利用 tar 命令将 linux-3.12 文件夹打包成 linux-3.12.tar，其次用 xz-utils 的 xz 命令将 linux-3.12.tar 压缩成 linux-3.12.tar.xz。

tar -cf linux-3.12.tar linux-3.12/
xz -z linux-3.12.tar

方法二（推荐）

tar -Jcf linux-3.12.tar.xz linux-3.12/

参考链接：
http://tukaani.org/xz/
http://zh.wikipedia.org/wiki/Xz



split a.txt -C 300k -d a.txt   
将a.txt文本文件分割为多个小文件，并保持每个小文件的大小不超过300k字节，而且尽量保持每行的完整性  
cat op.tar.xz*>op.tar.gz


### 如何创建和解压tar.bz2文件 ###
    tar xvjf filename.tar.bz2
    bzip2 -d my_file.tar.bz2 ; tar xvf my_file.tar

### 如何创建和解压tar.gz文件 ###
    tar zxvf filename.tar.gz

## 18.How to search function header file ##
Please do not use non-standard header files (e.g. malloc.h,linux/fcntl.h). They can cause portability problems, such as what Paul encountered.
   
If you are not sure which ones are standard, please look at the  man pages of corresponding functions (e.g. man 2 open, man malloc).

## 19.统计一个进程的线程数 ##

### 方法一: /proc ###

proc 伪文件系统，它驻留在 /proc 目录，这是最简单的方法来查看任何活动进程的线程数。 /proc 目录以可读文本文件形式输出，提供现有进程和系统硬件相关的信息如 CPU、中断、内存、磁盘等等.

	$ cat /proc/<pid>/status

上面的命令将显示进程 <pid> 的详细信息，包括过程状态（例如, sleeping, running)，父进程 PID，UID，GID，使用的文件描述符的数量，以及上下文切换的数量。输出也包括进程创建的总线程数如下所示。

	Threads: <N>

例如，检查 PID 20571进程的线程数：

	$ cat /proc/20571/status

或者，你可以在 /proc//task 中简单的统计子目录的数量，如下所示。

	$ ls /proc/<pid>/task | wc

这是因为，对于一个进程中创建的每个线程，在 /proc/<pid>/task 中会创建一个相应的目录，命名为其线程 ID。由此在/proc/<pid>/task 中目录的总数表示在进程中线程的数目。


### 方法二: ps ###

如果你是功能强大的 ps 命令的忠实用户，这个命令也可以告诉你一个进程（用“H”选项）的线程数。下面的命令将输出进程的线程数。“h”选项需要放在前面。

	$ ps hH p <pid> | wc -l


## 20. 目录介绍 ##
**管理类**

   - /bin    执行程序。
   - /sbin  管理员执行程序。
   - /dev   设备
   - /etc    配置文件
   - /boot 启动文件、内核
   - /var    记录一些变更东西，log

**用户类**

   - /root  root目录
   - /home 普通用户主目录存放地
   - /usr  是系统核心所在，包含了所有的共享文件。它是 unix 系统中最重要的目录之一，涵盖了二进制文件，各种文档，各种头文件，x，还有各种库文件；还有诸多程序，例如 ftp，telnet 等等。

**信息类**

   - /proc  查询各种系统信息
   - /lost-found 备份重要信息

**应用类**

   - /opt  安装用户应用软件，内核日志
   - /lib    存放动态链接库


## 21. 命令 ##

21.1 cat -n filename             打开文件时加上行号
    
21.2 chmod 设置访问权限

  1(-) 2(rw-) 3(r--)  4(r--)  
  文件的类型  

      a. “-”普通文件
      b.  "d"  文件夹
      c.   "s"  socket

   chmod a+x filename   给文件所有用户加执行权限
 
21.3 cp

    a. cp -a file1 file2   文件属性一致
    b. cp -p   保证它的权限
   
21.4 查看系统所有的服务

    chkconfig -all
 
21.5 top 修改nice
    # top—>r —>PID—>nice值

21.6 sync
sync命令 linux同步数据命令
格式： sync　
用途:更新 i-node 表，并将缓冲文件写到硬盘中。
功能：sync命令是在关闭Linux系统时使用的。 用户需要注意的是，不能用简单的关闭电源的方法关闭系统，因为Linux象其他Unix系统一样，在内存中缓存了许多数据，在关闭系统时需要进行内存数据与硬盘数据的同步校验，保证硬盘数据在关闭系统时是最新的，只有这样才能确保数据不会丢失。一般正常的关闭系统的过程是自动进行这些工作的，在系统运行过程中也会定时做这些工作，不需要用户干预。 sync命令是强制把内存中的数据写回硬盘，以免数据的丢失。用户可以在需要的时候使用此命令。
sync 命令运行 sync 子例程。如果必须停止系统，则运行 sync 命令以确保文件系统的完整性。sync 命令将所有未写的系统缓冲区写到磁盘中，包含已修改的 i-node、已延迟的块 I/O 和读写映射文件。