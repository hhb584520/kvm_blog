
## 常用工具大全--nice ## 

http://linuxtools-rst.readthedocs.io/zh_CN/latest/index.html  

http://www.computerhope.com/jargon/m/mkdir.htm

## lspci ##
lspci -Dn -s $bdf  
-D 选项表示在输出信息中显示设备的 domain  
-n 选项表示用数字的方式显示设备的 vendor ID 和 device ID  
-s 选项表示仅显示后面指定的一个设备的信息  

lspci -k -s $bdf  
-k 表示输出信息中显示正在使用的驱动和内核中可以支持该设备的模板。

lspci -v -s $bdf | grep SR-IOV  
查看PCI设备是否支持 SR-IOV 功能

## 时间格式 ##

date -d yesterday +%Y%m%d

## 创建用户 ##

	useradd -s /bin/sh -g group –G adm,root -d /usr/sam/ -m gem

此命令新建了一个用户gem，该用户的登录Shell是/bin/sh，它属于group用户组，同时又属于adm和root用户组，其中group用户组是其主组。其中-d和-m选项用来为登录名sam产生一个主目录/usr/sam（/usr为默认的用户主目录所在的父目录）。

## 同步时间 ##
    ntpdate vt-master 

## 统计某个文件夹下面的代码行数 ##
	wc -l `find -name *.c`

## 压缩和解压文件

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

## redhat update ## 
配置 /etc/yum.repo.d/ 源

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


执行 update

	# yum update

## How to search function header file ##
Please do not use non-standard header files (e.g. malloc.h,linux/fcntl.h). They can cause portability problems, such as what Paul encountered.
   
If you are not sure which ones are standard, please look at the  man pages of corresponding functions (e.g. man 2 open, man malloc).

