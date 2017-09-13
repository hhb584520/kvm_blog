# 1. 磁盘管理
## 1.1 创建分区

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

## 1.2 通过 fstab 设置开机挂载
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

### 1.2.1 通过浏览 /dev/disk/by-uuid/ 下的设备文件信息

	$ ls -l /dev/disk/by-uuid/
	------
	lrwxrwxrwx 1 root root 10 10-13 09:14 0909-090B -> ../../sdb5
	lrwxrwxrwx 1 root root 10 10-13 09:13 7c627a81-7a6b-4806-987b-b5a8a0a93645 -> ../../sda4

### 1.2.2 通过 blkid 命令

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

# 2. 卷组管理 #

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

## 2.1 manage volume group
我们可以先用 fdisk 对磁盘进行分区

	$ vgcreate vgnfs /dev/sdb1 /dev/sdb2 
	
上面我们就建立一个基于分区 /dev/sdb1 /dev/sdb2 创建卷组名"ccdnfs"
当然 vg 的管理还有很多命令，这里不一一列举，主要说明两个命令

- vgdisplay 显示当前的 vg 情况
- vgscan vgscan命令查找系统中存在的LVM卷组，并显示找到的卷组列表。vgscan命令仅显示找到的卷组的名称和LVM元数据类型，要得到卷组的详细信息需要使用vgdisplay命令。
- vgextend vgextend指令用于动态的扩展LVM卷组，它通过向卷组中添加物理卷来增加卷组的容量。
  	
	vgextend vgnfs /dev/sdb3

## 2.2 manage logical volume

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


**ext2/ext3** 

Unless you have patched your kernel with the ext2online patch it is necessary to unmount the file system before resizing it. (It seems that the online resizing patch is rather dangerous, so use at your own risk)

	$ umount /dev/myvg/homevol/dev/myvg/homevol
	$ resize2fs /dev/myvg/homevol
	$ mount /dev/myvg/homevol /home
            
If you don't have e2fsprogs 1.19 or later, you can download the ext2resize command from ext2resize.sourceforge.net and use that:

	$ umount /dev/myvg/homevol/dev/myvg/homevol
	$ ext2resize /dev/myvg/homevol
	$ mount /dev/myvg/homevol /home
            
**xfs**

XFS file systems must be mounted to be resized and the mount-point is specified rather than the device name.

    # xfs_growfs /home
                   
**Warning:Known Kernel Bug**

 Some kernel versions have problems with this syntax (2.6.0 is known to have this problem). In this case you have to explicitly specify the new size of the filesystem in blocks. This is extremely error prone as you must know the blocksize of your filesystem and calculate the new size based on those units.

 Example: If you were to resize a JFS file system to 4 gigabytes that has 4k blocks, you would write:

	# mount -o remount,resize=1048576 /home

# 3. check filesystem #

# 3.1 dev not mounted
if the filesystem is not mounted (but if it is as well):

	blkid -o value -s TYPE /dev/block/device
	or:
	
	file -Ls /dev/block/device

You'll generally need read access to the block device. However, in the case of blkid, if it can't read the device, it will try to get that information as cached in /run/blkid/blkid.tab or /etc/blkid.tab.

	lsblk -no FSTYPE /dev/block/device

will also give you that information, this time by querying the udev data (something like /run/udev/data/b$major:$minor).

# 3.2 dev mounted

	df -T

# 4. configure-ftp-server 
https://www.linux.com/blog/install-and-configure-ftp-server-redhatcentos-linux

# 4. ceph
http://www.vpsee.com/2015/07/install-ceph-on-centos-7/

#reference#
http://tldp.org/HOWTO/LVM-HOWTO/extendlv.html

http://www.cnblogs.com/gaojun/archive/2012/08/22/2650229.html