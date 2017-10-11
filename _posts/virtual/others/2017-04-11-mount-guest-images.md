# mount guest image #

## 1. Loop mount
### 1.1 Calulate offset
	
	$ fdisk -l ia32e_rhel7u2_kvm.img
	
	Disk rhel7u2_kvm.img: 21.5 GB, 21474836480 bytes, 41943040 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x000e5f14

    Device Boot                Start         End      Blocks   Id  System
	rhel7u2_kvm.img1   *        2048     1026047      512000   83  Linux
	rhel7u2_kvm.img2         1026048    41943039    20458496   8e  Linux LVM

	offset = Start(2048/1026048) * SectorSize(512) = 1048576
 
### 1.2 mount image
	
	mkdir -p /test
	mount -o offset=1048576 ia32e_rhel7u2_kvm.img /test

### 1.3 umount image

	umount /mnt
