# 1. 制作启动盘 #

## 1.1 linux 环境

1）格式化U盘。为了格式化我们首先需要 umount U盘：

查看设备：

	$ fdisk -l
	....

加入 /dev/sdb是我的U盘设备，umount：

	$ sudo umount /dev/sdb*

格式化U盘：

	$ sudo mkfs.vfat /dev/sdb –I

上面命令把U盘格式化为FAT格式。

2）制作启动U盘。

$ sudo dd if=~/home/bibi/Ubuntu_15_10_64.iso of=/dev/sdb
上面命令把ISO镜像写入到U盘，等待几分钟。

## 1.2 window 环境

	ultroiso

# 2. 安装 legacy 系统
## 2.1 redhat
http://www.hpiss.com/9598.html

## 2.2 ubuntu

# 3. 安装 UEFI 系统
除了 BIOS 要设置吗，还要在分区界面价格 UEFI 分区即可。