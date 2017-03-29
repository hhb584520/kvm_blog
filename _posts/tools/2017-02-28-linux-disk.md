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