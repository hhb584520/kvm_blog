# 1. check filesystem #

# 1.1 dev not mounted
if the filesystem is not mounted (but if it is as well):

	blkid -o value -s TYPE /dev/block/device
	or:
	
	file -Ls /dev/block/device

You'll generally need read access to the block device. However, in the case of blkid, if it can't read the device, it will try to get that information as cached in /run/blkid/blkid.tab or /etc/blkid.tab.

	lsblk -no FSTYPE /dev/block/device

will also give you that information, this time by querying the udev data (something like /run/udev/data/b$major:$minor).

# 1.2 dev mounted

	df -T

# 2. lvextend #


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

http://www.cnblogs.com/gaojun/archive/2012/08/22/2650229.html

To extend a logical volume you simply tell the lvextend command how much you want to increase the size. You can specify how much to grow the volume, or how large you want it to grow to:

	# lvextend -L12G /dev/myvg/homevol
	lvextend -- extending logical volume "/dev/myvg/homevol" to 12 GB
	lvextend -- doing automatic backup of volume group "myvg"
	lvextend -- logical volume "/dev/myvg/homevol" successfully extended
        
will extend /dev/myvg/homevol to 12 Gigabytes.

	# lvextend -L+1G /dev/myvg/homevol
	lvextend -- extending logical volume "/dev/myvg/homevol" to 13 GB
	lvextend -- doing automatic backup of volume group "myvg"
	lvextend -- logical volume "/dev/myvg/homevol" successfully extended
        
will add another gigabyte to /dev/myvg/homevol.


 After you have extended the logical volume it is necessary to increase the file system size to match. how you do this depends on the file system you are using.

 By default, most file system resizing tools will increase the size of the file system to be the size of the underlying logical volume so you don't need to worry about specifying the same size for each of the two commands.


## 2.1 ext2/ext3 ##


Unless you have patched your kernel with the ext2online patch it is necessary to unmount the file system before resizing it. (It seems that the online resizing patch is rather dangerous, so use at your own risk)

	# umount /dev/myvg/homevol/dev/myvg/homevol
	# resize2fs /dev/myvg/homevol
	# mount /dev/myvg/homevol /home
            
If you don't have e2fsprogs 1.19 or later, you can download the ext2resize command from ext2resize.sourceforge.net and use that:

	# umount /dev/myvg/homevol/dev/myvg/homevol
	# ext2resize /dev/myvg/homevol
	# mount /dev/myvg/homevol /home
            
## 2.2 reiserfs ##

Reiserfs file systems can be resized when mounted or unmounted as you prefer:

Online:

	# resize_reiserfs -f /dev/myvg/homevol
                  
Offline:

	# umount /dev/myvg/homevol
	# resize_reiserfs /dev/myvg/homevol
	# mount -treiserfs /dev/myvg/homevol /home
                  

## 2.3 xfs ##

XFS file systems must be mounted to be resized and the mount-point is specified rather than the device name.

    # xfs_growfs /home
            

## 2.4 jfs ##

Just like XFS the JFS file system must be mounted to be resized and the mount-point is specified rather than the device name. You need at least Version 1.0.21 of the jfs-utils to do this.

	# mount -o remount,resize /home
            
**Warning	Known Kernel Bug**

 Some kernel versions have problems with this syntax (2.6.0 is known to have this problem). In this case you have to explicitly specify the new size of the filesystem in blocks. This is extremely error prone as you must know the blocksize of your filesystem and calculate the new size based on those units.


 Example: If you were to resize a JFS file system to 4 gigabytes that has 4k blocks, you would write:

	# mount -o remount,resize=1048576 /home

#reference#
http://tldp.org/HOWTO/LVM-HOWTO/extendlv.html