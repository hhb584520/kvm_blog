# 目录 #

- 磁盘管理
- 卷组管理
- 文件系统
- CEPH
- NFS
- FTP


## 1. 磁盘管理
### 1.1 创建分区

fdisk /dev/sdb
 
输入m---n---p---1--回车---回车---p---w
也可通过脚本实现

	[root@hhb-kvm ~]# cat fdisk1.sh
	
	sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sdb
	  o # clear the in memory partition table
	  n # new partition
	  p # primary partition
	  1 # partition number 1
	    # default - start at beginning of disk
	  +100M # 100 MB boot parttion
	  n # new partition
	  p # primary partition
	  2 # partion number 2
	    # default, start immediately after preceding partition
	  +100M # /boot/efi
	  n # new partition
	  p # primary partition
	  3 # partion number 3
	    # default
	        # default
	  a # make a partition bootable
	  1 # bootable partition is partition 1 -- /dev/sdb
	  p # print the in-memory partition table
	  w # write the partition table
	  q # and we're done
	EOF

 
mkfs.ext4 /dev/sdb1
 
mkdir /disk2
 
mount /dev/sdb1 /disk2/

 
在/etc/fstab中添加：
/dev/sdb1            /disk2                  ext3    defaults        1 2

### 1.2 通过 fstab 设置开机挂载
fstab 文件大家都很熟悉，Linux 在启动的时候通过 fstab 中的信息挂载各个分区，一个典型的分区条目就像这样：

	/dev/sdb1 /disk2 vfat utf8,umask=0 0 0

/dev/sdb1 为需要挂载的分区，sdb1 是 Linux 检测硬盘时按顺序给分区的命名，一般来讲，这个名称并不会变化，但是如果你有多块硬盘，硬盘在电脑中的顺序变化的时候，相同的名称可能代表着不同的硬盘分区，如果你是从 USB 设备启动，与其他 USB 设备的插入顺序也会导致分区识别的困难。

因此上面的挂载的方法是有很大的隐患的，重启后硬盘的顺序可能发生变化，比如你把 nginx 的用户日志放在一个单独的分区上，那么重启后虽然设置了 fstab，但是由于顺序变了相同的分区号可能代表不同的硬盘分区了，这样就会导致某些分区上的数据服务不可用了。

这个时候 UUID 就派上用场了，UUID 全称是 Universally Unique Identifier，也就是说，每个分区有一个唯一的 UUID 值，这样就不会发生分区识别混乱的问题了。

在 fstab 中用 UUID 挂载分区，看起来向这样：
UUID=1234-5678 /mnt/usb vfat utf8,umask=0 0 0
在 UUID= 后面填入分区相应的 UUID 值，就可以正确挂载分区了。
那么，我们如何知道一个分区的 UUID 呢？
有 2 种方法：

#### 1.2.1 通过浏览 /dev/disk/by-uuid/ 下的设备文件信息

	$ ls -l /dev/disk/by-uuid/
	------
	lrwxrwxrwx 1 root root 10 10-13 09:14 0909-090B -> ../../sdb5
	lrwxrwxrwx 1 root root 10 10-13 09:13 7c627a81-7a6b-4806-987b-b5a8a0a93645 -> ../../sda4

#### 1.2.2 通过 blkid 命令

	$ blkid /dev/sdb5

/dev/sdb5: LABEL="SWAP" UUID="0909-090B" TYPE="vfat"
通过这三种方法都可以获得分区的 UUID，UUID 依据分区不同，长度和格式都不相同。
比如我最后把 /dev/sdb 挂载在了 /data1 目录下（不放心的话重启或者生成文件测试下，看挂载分区的空间被占用没）：

	文件系统       类型   容量  已用  可用 已用% 挂载点
	/dev/sda3      ext4   518G  2.7G  489G    1% /
	tmpfs          tmpfs   16G     0   16G    0% /dev/shm
	/dev/sda1      ext4  1008M   61M  896M    7% /boot
	/dev/sdb       ext4   1.8T  1.1G  1.7T    1% /data1

	grep -v '#' /etc/fstab |column -t
	UUID=0c685e8b-dbb3-4a1c-a106-3f1716ab34dd  /         ext4    defaults,noatime              1  1
	UUID=2d7f1bcf-06d1-486e-87df-404ba670fcd9  /boot     ext4    defaults,noatime              1  2
	.....
	UUID=870ebaf6-727f-48d3-b60c-f203339d94ac  /data1    ext4    defaults,noatime              0  0

## 2. 卷组管理

前面谈到，LVM是在磁盘分区和文件系统之间添加的一个逻辑层，来为文件系统屏蔽下层磁盘分区布局，提供一个抽象的盘卷，在盘卷上建立文件系统。首先我们讨论以下几个LVM术语：

物理存储介质（The physical media）：这里指系统的存储设备：硬盘，如：/dev/hda1、/dev/sda等等，是存储系统最低层的存储单元。

物理卷（physical volume）：物理卷就是指硬盘分区或从逻辑上与磁盘分区具有同样功能的设备(如RAID)，是LVM的基本存储逻辑块，但和基本的物理存储介质（如分区、磁盘等）比较，却包含有与LVM相关的管理参数。

卷组（Volume Group）：LVM卷组类似于非LVM系统中的物理硬盘，其由物理卷组成。可以在卷组上创建一个或多个“LVM分区”（逻辑卷），LVM卷组由一个或多个物理卷组成。

逻辑卷（logical volume）：LVM的逻辑卷类似于非LVM系统中的硬盘分区，在逻辑卷之上可以建立文件系统(比如/home或者/usr等)。

PE（physical extent）：每一个物理卷被划分为称为PE(Physical Extents)的基本单元，具有唯一编号的PE是可以被LVM寻址的最小单元。PE的大小是可配置的，默认为4MB。

LE（logical extent）：逻辑卷也被划分为被称为LE(Logical Extents) 的可被寻址的基本单位。在同一个卷组中，LE的大小和PE是相同的，并且一一对应。

简单来说就是：

PV:是物理的磁盘分区

VG:LVM中的物理的磁盘分区，也就是PV，必须加入VG，可以将VG理解为一个仓库或者是几个大的硬盘。

LV：也就是从VG中划分的逻辑分区

### 2.1 添加新的 PV

一个硬盘在能够被LVM使用之前一定要初始化，可以使用pvcreate命令将PVRA的信息写入到硬盘当中，而这样被写入了PVRA信息的硬盘，就叫做PV。

	$ pvcreate /dev/ubuntu-vg/sdb1

如果之前已经有PVRA的信息在这块硬盘上，也就是说，这块硬盘之前可能被其他的LVM使用过，那么你将得到一个报错信息：

	$ pvcreate: The Physical Volume already belongs to a Volume Group

如果你确定要初始化这块硬盘，那么可以带上-f的参数来强行执行

	$ pvcreate -f /dev/ubuntu-vg/sdb1

注意：如果是启动盘，还应该加上-B的选项。这样做将会在硬盘头保留2912KB的空间给LVM表头（LVM header），相关的信息，可以参见《LVM的结构信息》。如果你想要做启动盘的镜像的话，可以参考后面的《根盘镜像》章节。

将硬盘初始化以后，就可以将该PV添加到已经存在的VG当中去了：

	$ vgextend vgnfs /dev/ubuntu-vg/sdb1
	
	$ vgdisplay -v vg01

### 2.2 create volume group
我们可以先用 fdisk 对磁盘进行分区

	$ vgcreate vgnfs /dev/sdb1 /dev/sdb2 
	
上面我们就建立一个基于分区 /dev/sdb1 /dev/sdb2 创建卷组名"ccdnfs"
当然 vg 的管理还有很多命令，这里不一一列举，主要说明两个命令

- vgdisplay 显示当前的 vg 情况
- vgscan vgscan命令查找系统中存在的LVM卷组，并显示找到的卷组列表。vgscan命令仅显示找到的卷组的名称和LVM元数据类型，要得到卷组的详细信息需要使用vgdisplay命令。
- vgextend vgextend指令用于动态的扩展LVM卷组，它通过向卷组中添加物理卷来增加卷组的容量。
  	
	$ vgextend vgnfs /dev/sdb3

### 2.3 manage logical volume

使用lvcreate命令在卷组"vgnfs"上创建一个 1TB 的逻辑卷。在命令行中输入下面的命令：

	lvcreate -L 1T -n lvrepo vgnfs
	lvcreate -L 1T -n lvrampup vgnfs
	lvcreate -L 2T -n lvimages vgnfs
	lvcreate -L 8T -n lvlog vgnfs

当然管理 lv 命令很多，下面着重讲几个比较常用的命令。

- lvdisplay 

	lvdisplay命令用于显示LVM逻辑卷空间大小、读写状态和快照信息等属性。如果省略"逻辑卷"参数，则lvdisplay命令显示所有的逻辑卷属性。否则，仅显示指定的逻辑卷属性。

- lvextend

To extend a logical volume you simply tell the lvextend command how much you want to increase the size. You can specify how much to grow the volume, or how large you want it to grow to:

	$ lvextend -L 12G /dev/myvg/homevol
	$ lvextend -L+1G /dev/myvg/homevol

After you have extended the logical volume it is necessary to increase the file system size to match. how you do this depends on the file system you are using.

By default, most file system resizing tools will increase the size of the file system to be the size of the underlying logical volume so you don't need to worry about specifying the same size for each of the two commands.

	$ mount | column -t  # see local filesystem

**ext2/ext3/ext4** 

Unless you have patched your kernel with the ext2online patch it is necessary to unmount the file system before resizing it. (It seems that the online resizing patch is rather dangerous, so use at your own risk)

	$ resize2fs /dev/myvg/homevol

            
If you don't have e2fsprogs 1.19 or later, you can download the ext2resize command from ext2resize.sourceforge.net and use that:

	$ ext2resize /dev/myvg/homevol
            
**xfs**

XFS file systems must be mounted to be resized and the mount-point is specified rather than the device name.

    # xfs_growfs /home
                   
**Warning:Known Kernel Bug**

 Some kernel versions have problems with this syntax (2.6.0 is known to have this problem). In this case you have to explicitly specify the new size of the filesystem in blocks. This is extremely error prone as you must know the blocksize of your filesystem and calculate the new size based on those units.

 Example: If you were to resize a JFS file system to 4 gigabytes that has 4k blocks, you would write:

	# mount -o remount,resize=1048576 /home

## 3. check filesystem #

### 3.1 dev not mounted
if the filesystem is not mounted (but if it is as well):

	blkid -o value -s TYPE /dev/block/device
	or:
	
	file -Ls /dev/block/device

You'll generally need read access to the block device. However, in the case of blkid, if it can't read the device, it will try to get that information as cached in /run/blkid/blkid.tab or /etc/blkid.tab.

	lsblk -no FSTYPE /dev/block/device

will also give you that information, this time by querying the udev data (something like /run/udev/data/b$major:$minor).

### 3.2 dev mounted

	df -T

## 4. ceph
http://www.vpsee.com/2015/07/install-ceph-on-centos-7/

## 5. NFS

### 5.1 简介

NFS 是Network File System的缩写，即网络文件系统。一种使用于分散式文件系统的协定，由Sun公司开发，于1984年向外公布。功能是通过网络让不同的机器、不同的操作系统能够彼此分享个别的数据，让应用程序在客户端通过网络访问位于服务器磁盘中的数据，是在类Unix系统间实现磁盘文件共享的一种方法。

NFS 的基本原则是“容许不同的客户端及服务端通过一组RPC分享相同的文件系统”，它是独立于操作系统，容许不同硬件及操作系统的系统共同进行文件的分享。

#### 5.1.1 NFS系统守护进程

nfsd：它是基本的NFS守护进程，主要功能是管理客户端是否能够登录服务器；
mountd：它是RPC安装守护进程，主要功能是管理NFS的文件系统。当客户端顺利通过nfsd登录NFS服务器后，在使用NFS服务所提供的文件前，还必须通过文件使用权限的验证。它会读取NFS的配置文件/etc/exports来对比客户端权限。
portmap：主要功能是进行端口映射工作。当客户端尝试连接并使用RPC服务器提供的服务（如NFS服务）时，portmap会将所管理的与服务对应的端口提供给客户端，从而使客户可以通过该端口向服务器请求服务。

#### 5.1.2 NFS的协议

NFS在文件传送或信息传送过程中依赖于RPC协议。RPC，远程过程调用 (Remote Procedure Call) 是能使客户端执行其他系统中程序的一种机制。NFS本身是没有提供信息传输的协议和功能的，但NFS却能让我们通过网络进行资料的分享，这是因为NFS使用了一些其它的传输协议。而这些传输协议用到这个RPC功能的。可以说NFS本身就是使用RPC的一个程序。或者说NFS也是一个RPC SERVER。所以只要用到NFS的地方都要启动RPC服务，不论是NFS SERVER或者NFS CLIENT。这样SERVER和CLIENT才能通过RPC来实现PROGRAM PORT的对应。可以这么理解RPC和NFS的关系：NFS是一个文件系统，而RPC是负责负责信息的传输。

### 5.2 安装和配置NFS服务 
#### 5.2.1 系统环境 

系统平台：CentOS release 5.6 (Final)

NFS Server IP: 192.168.1.108
NFS Client IP: 192.168.1.109

防火墙已关闭/iptables: Firewall is not running.

	$ iptables -F

SELINUX=disabled

#### 5.2.2 安装

NFS的安装是非常简单的，只需要两个软件包即可，而且在通常情况下，是作为系统的默认包安装的。

nfs-utils-* ：包括基本的NFS命令与监控程序 
portmap-* ：支持安全NFS RPC服务的连接

- 查看系统是否已安装NFS

	rpm -qa | grep nfs

系统默认已安装了nfs-utils portmap 两个软件包。

- 如果当前系统中没有安装NFS所需的软件包，需要手工进行安装。nfs-utils 和portmap 两个包的安装文件在系统光盘中都会有。

	$ mount /dev/cdrom /mnt/cdrom/
	$ cd /mnt/cdrom/CentOS/
	$ rpm -ivh portmap-4.0-65.2.2.1.i386.rpm 
	$ rpm -ivh nfs-utils-1.0.9-50.el5.i386.rpm
	$ rpm -q nfs-utils portmap

#### 5.2.3 配置 ##

1、将NFS Server 的/home/david/ 共享给192.168.1.0/24网段，权限读写。

服务器端文件详细如下：

	$ vi /etc/exports
		/home/david 192.168.1.0/24 (rw,sync,no_root_squash)

	$ iptables -F

如果修改 /etc/exports， 无须重启 nfs
直接使用 exportfs -av

	exportfs - maintain table of exported NFS file systems

2、重启portmap 和nfs 服务

RHEL6.*
	$ service portmap restart
	$ service nfs restart
	$ exportfs

RHEL7.*
	systemctl start nfs
	systemctl enable nfs

3、客户端使用showmount命令查询NFS的共享状态

	$ showmount -e NFS服务器IP

这一步有些时候会过很久，出一个 RPC timeout 错误，这里面很多原因，我遇到以下两种：防火墙没关，路由问题。防火墙上面已讲
下面重点讲一下 路由问题

	$ traceroute ccd-nfs.sh.intel.com
	[root@hhb-xen ~]# traceroute ccd-nfs.sh.intel.com
	traceroute to ccd-nfs.sh.intel.com (10.239.53.218), 30 hops max, 60 byte packets
	 1  10.239.159.2 (10.239.159.2)  0.801 ms  0.778 ms  0.768 ms
	 2  10.239.221.69 (10.239.221.69)  0.492 ms 10.239.221.129 (10.239.221.129)  0.309 ms 10.239.221.69 (10.239.221.69)  0.477 ms^C

	$ route add default gw 10.239.159.2 p3p1


4、客户端挂载NFS服务器中的共享目录

命令格式

	# mount NFS服务器IP:共享目录 本地挂载点目录
	# mount 192.168.1.108:/home/david/ /tmp/david/
	# mount |grep nfs

挂载成功。

查看文件是否和服务器端一致。

5、NFS的共享权限和访问控制


	# chmod 777 -R /home/david/
	# cat /var/lib/nfs/etab


默认就有sync，wdelay，hide 等等，no_root_squash 是让root保持权限，root_squash 是把root映射成nobody，no_all_squash 不让所有用户保持在挂载目录中的权限。所以，root建立的文件所有者是nfsnobody。

下面我们使用普通用户挂载、写入文件测试。

	$ su - david
	$ cd /tmp/david/
	$ touch 2013david


普通用户写入文件时就是自己的名字，这也就保证了服务器的安全性。
　　关于权限的分析

　　1. 客户端连接时候，对普通用户的检查

　　　　a. 如果明确设定了普通用户被压缩的身份，那么此时客户端用户的身份转换为指定用户；

　　　　b. 如果NFS server上面有同名用户，那么此时客户端登录账户的身份转换为NFS server上面的同名用户；

　　　　c. 如果没有明确指定，也没有同名用户，那么此时 用户身份被压缩成nfsnobody；

　　2. 客户端连接的时候，对root的检查

　　　　a. 如果设置no_root_squash，那么此时root用户的身份被压缩为NFS server上面的root；

　　　　b. 如果设置了all_squash、anonuid、anongid，此时root 身份被压缩为指定用户；

　　　　c. 如果没有明确指定，此时root用户被压缩为nfsnobody；

　　　　d. 如果同时指定no_root_squash与all_squash 用户将被压缩为 nfsnobody，如果设置了anonuid、anongid将被压缩到所指定的用户与组；

6、卸载已挂载的NFS共享目录

	# umount /tmp/david/


#### 5.2.4 启动自动挂载nfs文件系统 #

格式：

	<server>:</remote/export> </local/directory> nfs < options> 0 0
	# vi /etc/fstab

保存退出，重启系统。查看/home/david 有没有自动挂载。

### 5.3. 其他
#### 5.3.1 相关命令 
**exportfs** 

如果我们在启动了NFS之后又修改了/etc/exports，是不是还要重新启动nfs呢？这个时候我们就可以用exportfs 命令来使改动立刻生效，该命令格式如下：

	$ exportfs [-aruv]
	　　-a 全部挂载或卸载 /etc/exports中的内容 
	　　-r 重新读取/etc/exports 中的信息 ，并同步更新/etc/exports、/var/lib/nfs/xtab
	　　-u 卸载单一目录（和-a一起使用为卸载所有/etc/exports文件中的目录）
	　　-v 在export的时候，将详细的信息输出到屏幕上。

具体例子： 

	$ exportfs -au 卸载所有共享目录
	$ exportfs -rv 重新共享所有目录并输出详细信息

**nfsstat**

查看NFS的运行状态，对于调整NFS的运行有很大帮助。

**rpcinfo**

查看rpc执行信息，可以用于检测rpc运行情况的工具，利用rpcinfo -p 可以查看出RPC开启的端口所提供的程序有哪些。

**showmount**

　　-a 显示已经于客户端连接上的目录信息
　　-e IP或者hostname 显示此IP地址分享出来的目录

**netstat**

可以查看出nfs服务开启的端口，其中nfs 开启的是2049，portmap 开启的是111，其余则是rpc开启的。

最后注意两点，虽然通过权限设置可以让普通用户访问，但是挂载的时候默认情况下只有root可以去挂载，普通用户可以执行sudo。

NFS server 关机的时候一点要确保NFS服务关闭，没有客户端处于连接状态！通过showmount -a 可以查看，如果有的话用kill killall pkill 来结束，（-9 强制结束）

#### 5.3.2 强制 Umount NFS
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

#### 5.3.3 NFS服务器的配置

NFS服务器的配置相对比较简单，只需要在相应的配置文件中进行设置，然后启动NFS服务器即可。

NFS的常用目录

	/etc/exports                           NFS服务的主要配置文件
	/usr/sbin/exportfs                   NFS服务的管理命令
	/usr/sbin/showmount              客户端的查看命令
	/var/lib/nfs/etab                      记录NFS分享出来的目录的完整权限设定值
	/var/lib/nfs/xtab                      记录曾经登录过的客户端信息

NFS服务的配置文件为 /etc/exports，这个文件是NFS的主要配置文件，不过系统并没有默认值，所以这个文件不一定会存在，可能要使用vim手动建立，然后在文件里面写入配置内容。

/etc/exports文件内容格式：

	<输出目录> [客户端1 选项（访问权限,用户映射,其他）] [客户端2 选项（访问权限,用户映射,其他）]

a. 输出目录：

输出目录是指NFS系统中需要共享给客户机使用的目录；

b. 客户端：

客户端是指网络中可以访问这个NFS输出目录的计算机

客户端常用的指定方式

- 指定ip地址的主机：192.168.0.200
- 指定子网中的所有主机：192.168.0.0/24 192.168.0.0/255.255.255.0
- 指定域名的主机：david.bsmart.cn
- 指定域中的所有主机：*.bsmart.cn
- 所有主机：*

c. 选项：

选项用来设置输出目录的访问权限、用户映射等。

NFS主要有3类选项：

访问权限选项

- 设置输出目录只读：ro
- 设置输出目录读写：rw

用户映射选项

- all_squash：将远程访问的所有普通用户及所属组都映射为匿名用户或用户组（nfsnobody）；
- no_all_squash：与all_squash取反（默认设置）；
- root_squash：将root用户及所属组都映射为匿名用户或用户组（默认设置）；
- no_root_squash：与rootsquash取反；
- anonuid=xxx：将远程访问的所有用户都映射为匿名用户，并指定该用户为本地用户（UID=xxx）；
- anongid=xxx：将远程访问的所有用户组都映射为匿名用户组账户，并指定该匿名用户组账户为本地用户组账户（GID=xxx）；

其它选项

- secure：限制客户端只能从小于1024的tcp/ip端口连接nfs服务器（默认设置）；
- insecure：允许客户端从大于1024的tcp/ip端口连接服务器；
- sync：将数据同步写入内存缓冲区与磁盘中，效率低，但可以保证数据的一致性；
- async：将数据先保存在内存缓冲区中，必要时才写入磁盘；
- wdelay：检查是否有相关的写操作，如果有则将这些写操作一起执行，这样可以提高效率（默认设置）；
- no_wdelay：若有写操作则立即执行，应与sync配合使用；
- subtree：若输出目录是一个子目录，则nfs服务器将检查其父目录的权限(默认设置)；
- no_subtree：即使输出目录是一个子目录，nfs服务器也不检查其父目录的权限，这样可以提高效率；

## 6. configure-ftp-server 
https://www.linux.com/blog/install-and-configure-ftp-server-redhatcentos-linux

## 7. 参考资料 #

http://www.idcyunwei.org/post/32.html

http://tldp.org/HOWTO/LVM-HOWTO/extendlv.html

http://www.cnblogs.com/gaojun/archive/2012/08/22/2650229.html