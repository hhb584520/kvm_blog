## 常用工具大全--nice ##

http://linuxtools-rst.readthedocs.io/zh_CN/latest/index.html  
http://www.computerhope.com/jargon/m/mkdir.htm

## 1. 查看系统信息
### 1.1 查看系统是64位还是32位
1、getconf LONG_BIT or getconf WORD_BIT
2、file /bin/ls
3、lsb_release -a

### 1.2 查看Linux的内核版本

cat /proc/version 

### 1.3 查看Linux的发行版
登录到服务器执行 lsb_release -a ,即可列出所有版本信息,例如:
   [root@3.5.5Biz-46 ~]# [root@q1test01 ~]# lsb_release -a
   LSB Version:    :core-3.0-amd64:core-3.0-ia32:core-3.0-noarch:graphics-3.0-amd64:graphics-3.0-
   ia32:graphics-3.0-noarch
   Distributor ID: RedHatEnterpriseAS
   Description:    Red Hat Enterprise Linux AS release 4 (Nahant Update 2)
   Release:        4
   Codename:       NahantUpdate2
   注:这个命令适用于所有的linux，包括Redhat、SuSE、Debian等发行版。

## 2. Install software
### 2.1 wine install #

http://www.tecmint.com/install-wine-in-rhel-centos-and-fedora/

### 2.2 redhat ##
https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/pdf/System_Administrators_Guide/Red_Hat_Enterprise_Linux-7-System_Administrators_Guide-en-US.pdf 

### 2.3 配置安装源 redhat
#### 2.1.1 配置 /etc/yum.repo.d/ 源 ###

$ cat linux-ftp.repo  
[rhel$releasever]  
name=Red Hat Enterprise Linux $releasever  
baseurl=http://linux-ftp.sh.intel.com/pub/ISO/redhat/redhat-rhel/RHEL-7.3-Snapshot-4/Server/x86_64/os/  
enabled=1  
gpgcheck=0  

[rhel6_optional]  
name=Red Hat Enterprise Linux rhel6_optional  
baseurl=http://linux-ftp.sh.intel.com/pub/ISO/redhat/redhat-rhel/RHEL-7.3-Snapshot-4/Server-optional/x86_64/os/  
enabled=1  
gpgcheck=0  


执行 yum update

#### 2.1.1 配置本地 yum 源

本文配置本地yum源是把RedHat 7的系统盘内容复制到服务器硬盘的目录/RH7ISO中，然后配置yum指向该目录。

- 首先挂载光驱到/mnt目录 ：mount /dev/cdrom /mnt
- 复制系统盘的内容到/rhel7iso目录中：cp -R /mnt/* rhel7iso
- 进入yum配置目录 : cd /etc/yum.repos.d/ 
- 建立yum配置文件: touch  rhel7_iso.repo 
- 编辑配置文件，添加以下内容: vim rhel7_iso.repo 

    [RHEL7ISO]
    name=rhel7iso  
    baseurl=file:///rhel7iso  
    enabled=1  
    gpgcheck=1  
    gpgkey=file:///rhel7iso/RPM-GPG-KEY-redhat-release  

- 清除yum缓存: yum clean all 
- 缓存本地yum源中的软件包信息: yum makecache 

配置完毕！可以直接使用yum install packname进行yum安装了！

### 2.2 配置安装源 ubuntu
请注意：
如果在安装中部分软件无法安装成功，说明软件源中缺包，先尝试使用命令#apt-get update更新软件源后尝试安装。如果还是不行，需要更换软件源。更换步骤：

- 输入命令#cp /etc/apt/sources.list /etc/apt/sources.list_backup
- 输入命令#vi /etc/apt/sources.list
- 添加其他软件源（推荐使用163、中科大、上海交大等速度较快的国内源）
- 保存并关闭窗口
- 输入命令：#apt-get update

#### 2.2.1 安装远程源 ###
for ubuntu14.04.4 source
 
gedit /etc/apt/sources.list

    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty main restricted
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty main restricted
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates main restricted
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates main restricted
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty universe
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty universe
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates universe
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates universe
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty multiverse
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates multiverse
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-backports main restricted universe multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-backports main restricted universe multiverse

### 2.2.2 安装本地源 ###
第一步转到镜像的下载目录，挂载ISO镜像挂载至/media/cdrom下。
代码:
sudo mount -o loop -t iso9660 update-i386-20080312-CD1.iso /media/cdrom

第二步手动添加ISO镜像至软件源列表，这样就可以在软件库里找到ISO上所有的软件包
代码:
sudo apt-cdrom -m -d=/media/cdrom add

第三步刷新软件库
代码:
sudo apt-get update

注意，执行完成后查看/etc/apt/sources.list文件，确保文件如下一行在文件顶部或者在网络源前面，否者，安装软件的时候系统还是优先从网络上下载【建议把除了dvd本地源之外的下面所有项注视掉，不建议删除，之后在apt-get update更新下】
deb cdrom:[Ubuntu 9.04 _Jaunty Jackalope_ - Release i386 (20090421.3)]/ jaunty main restricted

之后就可以用apt-get install ** 来安装软件包了，不过有点问题，这命令执行一次可能会不成功，多执行几次就OK了

## 3. 安装 自己编译 Driver ##
下面以 sgx driver 为例
git clone https://github.com/01org/linux-sgx-driver.git

### 3.1 for redhat

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

### 3.2 for ubuntu

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

## 4. 修改时区和时间
### 4.1 时区

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

### 4.2 时间

查看时间和日期

    date

设置时间和日期

    将系统日期设定成1996年6月10日的命令
    date -s 06/22/96

    将系统时间设定成下午1点52分0秒的命令
    date -s 13:52:00 

### 4.3 时间格式

	date -d yesterday +%Y%m%d

### 4.4 写时间和日期到BIOS
将当前时间和日期写入BIOS，避免重启后失效
    hwclock -w

### 4.5 同步时间 ##
    ntpdate vt-master 

## 5.压缩和解压文件

### 5.1 解压 xz 格式文件 ###
方法一：
需要用到两步命令，首先利用 xz-utils 的 xz 命令将 linux-3.12.tar.xz 解压为 linux-3.12.tar，其次用 tar 命令将 linux-3.12.tar 完全解压。

xz -d linux-3.12.tar.xz
tar -xf linux-3.12.tar

方法二（推荐）

tar -Jxf linux-3.12.tar.xz

### 5.2 创建 xz 格式文件 ###
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


### 5.3 如何创建和解压tar.bz2文件 ###
    tar xvjf filename.tar.bz2
    bzip2 -d my_file.tar.bz2 ; tar xvf my_file.tar

### 5.4 如何创建和解压tar.gz文件 ###
    tar zxvf filename.tar.gz

## 6. 用户管理
### 6.1 创建用户

	useradd -s /bin/sh -g group –G adm,root -d /usr/sam/ -m gem

此命令新建了一个用户gem，该用户的登录Shell是/bin/sh，它属于group用户组，同时又属于adm和root用户组，其中group用户组是其主组。其中-d和-m选项用来为登录名sam产生一个主目录/usr/sam（/usr为默认的用户主目录所在的父目录）。

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


## 21. 常用命令 ##

### 21.1 cat -n filename             打开文件时加上行号
    
### 21.2 chmod 设置访问权限

  1(-) 2(rw-) 3(r--)  4(r--)  
  文件的类型  

      a. “-”普通文件
      b.  "d"  文件夹
      c.   "s"  socket

   chmod a+x filename   给文件所有用户加执行权限
 
### 21.3 cp

    a. cp -a file1 file2   文件属性一致
    b. cp -p   保证它的权限
   
### 21.4 查看系统所有的服务

    chkconfig -all
 

### 21.5 sync
sync命令 linux同步数据命令
格式： sync　
用途:更新 i-node 表，并将缓冲文件写到硬盘中。
功能：sync命令是在关闭Linux系统时使用的。 用户需要注意的是，不能用简单的关闭电源的方法关闭系统，因为Linux象其他Unix系统一样，在内存中缓存了许多数据，在关闭系统时需要进行内存数据与硬盘数据的同步校验，保证硬盘数据在关闭系统时是最新的，只有这样才能确保数据不会丢失。一般正常的关闭系统的过程是自动进行这些工作的，在系统运行过程中也会定时做这些工作，不需要用户干预。 sync命令是强制把内存中的数据写回硬盘，以免数据的丢失。用户可以在需要的时候使用此命令。
sync 命令运行 sync 子例程。如果必须停止系统，则运行 sync 命令以确保文件系统的完整性。sync 命令将所有未写的系统缓冲区写到磁盘中，包含已修改的 i-node、已延迟的块 I/O 和读写映射文件。

### 21.6 统计一个进程的线程数 ##

proc 伪文件系统，它驻留在 /proc 目录，这是最简单的方法来查看任何活动进程的线程数。 /proc 目录以可读文本文件形式输出，提供现有进程和系统硬件相关的信息如 CPU、中断、内存、磁盘等等.下面命令将显示进程 <pid> 的详细信息，包括过程状态（例如, sleeping, running)，父进程 PID，UID，GID，使用的文件描述符的数量，以及上下文切换的数量。

	$ cat /proc/<pid>/status | grep Threads

或者，你可以在 /proc//task 中简单的统计子目录的数量，如下所示。

	$ ls /proc/<pid>/task | wc

这是因为，对于一个进程中创建的每个线程，在 /proc/<pid>/task 中会创建一个相应的目录，命名为其线程 ID。由此在/proc/<pid>/task 中目录的总数表示在进程中线程的数目。

### 21.7 统计某个文件夹下面的代码行数

	wc -l `find -name *.c`

### 21.8. 提取ISO 文件夹里面的文件

	mkdir /mnt/iso  
	mount -o loop *.iso /mnt/iso
	ls /mnt/iso

### 21.9. udev 介绍
http://www.ibm.com/developerworks/cn/linux/l-cn-udev/index.html?ca=drs-cn-0304




 
