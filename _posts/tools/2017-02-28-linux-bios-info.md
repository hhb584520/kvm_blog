
# 1.BIOS配置及查看
## 1.1 判断Linux系统是否在UEFI模式下安装的

在Linux终端里运行下面的命令

[ -d /sys/firmware/efi ] && echo "Installed in UEFI mode" || echo "Installed in Legacy mode"
怎么确信操作系统是以UEFI模式启动的

首先，你可以在主板固件设置里禁用BIOS以及CSM模块，只启用原生UEFI模式．另外，你可以查看Linux系统上是否有/sys/firmware/efi这个目录．如果这个目录存在，那么系统就是以UEFI模式启动的．

## 1.2 UEFI 介绍
UEFI，全称Unified Extensible Firmware Interface，即“统一的可扩展固件接口”，是一种详细描述全新类型接口的标准，是适用于电脑的标准固件接口，旨在代替BIOS（基本输入/输出系统）。此标准由UEFI联盟中的140多个技术公司共同创建，其中包括微软公司。UEFI旨在提高软件互操作性和解决BIOS的局限性。

要详细了解UEFI，还得从BIOS讲起。我们都知道，每一台普通的电脑都会有一个BIOS，用于加载电脑最基本的程式码，担负着初始化硬件，检测硬件功能以及引导操作系统的任务。UEFI就是与BIOS相对的概念，这种接口用于操作系统自动从预启动的操作环境，加载到一种操作系统上，从而达到开机程序化繁为简节省时间的目的。传统BIOS技术正在逐步被UEFI取而代之，在最近新出厂的电脑中，很多已经使用UEFI，使用UEFI模式安装操作系统是趋势所在。

作为传统BIOS（Basic Input/Output System）的继任者，UEFI拥有前辈所不具备的诸多功能，比如图形化界面、多种多样的操作方式、允许植入硬件驱动等等。这些特性让UEFI相比于传统BIOS更加易用、更加多功能、更加方便。而Windows 8在发布之初就对外宣布全面支持UEFI，这也促使了众多主板厂商纷纷转投UEFI，并将此作为主板的标准配置之一。

UEFI抛去了传统BIOS需要长时间自检的问题，让硬件初始化以及引导系统变得简洁快速。换种方式说，UEFI已经把电脑的BIOS变得不像是BIOS，而是一个小型固化在主板上的操作系统一样，加上UEFI本身的开发语言已经从汇编转变成C语言，高级语言的加入让厂商深度开发UEFI变为可能。

## 1.3 BIOS 设置

https://linux.cn/article-8481-1.html

**快速启动** — 此功能可以通过在硬件初始化时使用快捷方式来加快引导过程。这很好用，但有时候会使 USB 设备不能初始化，导致计算机无法从 USB 闪存驱动器或类似的设备启动。因此禁用快速启动可能有一定的帮助，甚至是必须的；你可以让它保持激活，而只在 Linux 安装程序启动遇到问题时将其停用。请注意，此功能有时可能会以其它名字出现。在某些情况下，你必须启用 USB 支持，而不是禁用快速启动功能。

**安全启动** — Fedora，OpenSUSE，Ubuntu 以及其它的发行版官方就支持安全启动；但是如果在启动引导加载程序或内核时遇到问题，可能需要禁用此功能。不幸的是，没办法具体描述怎么禁用，因为不同计算机的设置方法也不同。请参阅我的安全启动页面获取更多关于此话题的信息。

注意： 一些教程说安装 Linux 时需要启用 BIOS/CSM/legacy 支持。通常情况下，这样做是错的。启用这些支持可以解决启动安装程序涉及的问题，但也会带来新的问题。以这种方式安装的教程通常可以通过“引导修复”来解决这些问题，但最好从一开始就做对。本页面提供了帮助你以 EFI 模式启动 Linux 安装程序的提示，从而避免以后的问题。

**CSM/legacy 选项** — 如果你想以 EFI 模式安装，请关闭这些选项。一些教程推荐启用这些选项，有时这是必须的 —— 比如，有些附加视频卡需要在固件中启用 BIOS 模式。尽管如此，大多数情况下启用 CSM/legacy 支持只会无意中增加以 BIOS 模式启动 Linux 的风险，但你并不想这样。请注意，安全启动和 CSM/legacy 选项有时会交织在一起，因此更改任一选项之后务必检查另一个。


下面以 redhat 配置为例
[root@hhb-xen ]# cd /boot/efi/EFI/redhat/
[root@hhb-xen ]# ls
BOOT.CSV  fonts  gcdx64.efi  grub.cfg  grubenv  grubx64.efi  MokManager.efi  shim.efi  shim-redhat.efi

	menuentry 'Red Hat Enterprise Linux Server (3.10.0-327.el7.x86_64) 7.2 (Maipo)' --class red --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-ede2fb80-2e01-4dab-a556-fc4c5783f06b' {
	        load_video
	        set gfxpayload=keep
	        insmod gzio
	        insmod part_gpt
	        insmod xfs
	        set root='hd0,gpt2'
	        if [ x$feature_platform_search_hint = xy ]; then
	          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,gpt2 --hint-efi=hd0,gpt2 --hint-baremetal=ahci0,gpt2  c323fcb5-e9a2-4716-97bf-0e91a7ab4d26
	        else
	          search --no-floppy --fs-uuid --set=root c323fcb5-e9a2-4716-97bf-0e91a7ab4d26
	        fi
	        linuxefi /vmlinuz-3.10.0-327.el7.x86_64 root=/dev/mapper/rhel-root ro crashkernel=auto rd.lvm.lv=rhel/root rd.lvm.lv=rhel/swap rhgb quiet LANG=en_US.UTF-8
	        initrdefi /initramfs-3.10.0-327.el7.x86_64.img
	}


# 2.Linux 查看 BIOS 信息

做Linux系统底层的测试，有时候需要关注BIOS的信息（包括基本信息、检测到的CPU和内存等）。除了在开机启动时进入到BIOS之外，还可以在Linux系统中直接查看BIOS的信息，一般可以使用dmidecode命令（还有biosdecode命令可参考）；另外，在Windows中可以使用“DMIScope”软件（收费软件，笔者未使用过）来查看和修改BIOS。

SMBIOS (System Management BIOS)是主板或系统制造者以标准格式显示产品管理信息所需遵循的统一规范。
DMI (Desktop Management Interface, DMI)就是帮助收集电脑系统信息的管理系统，DMI信息的收集必须在严格遵照SMBIOS规范的前提下进行。
SMBIOS和DMI是由行业指导机构Desktop Management Task Force (DMTF)起草的开放性的技术标准；不过DMTF宣布DMI的生命期在2005年结束了。

使用dmidecode命令时，如果不加任何参数，则打印出所有类型的信息；而加上“-t type_num”或者“-t keywords”可以查看某个类型信息。

- dmidecode
- dmidecode -t 1
- dmidecode -t system


 
**SMBIOS specification**

    Type	Description
    0	BIOS Information
    1	System Information
    2	Baseboard (or Module) Information
    3	System Enclosure or Chassis
    4	Processor Information
    5	Memory Controller Information (Obsolete)
    6	Memory Module Information (Obsolete)
    7	Cache Information
    8	Port Connector Information
    9	System Slots
    10	On Board Devices Information
    11	OEM Strings
    12	System Configuration Options
    13	BIOS Language Information
    14	Group Associations
    15	System Event Log
    16	Physical Memory Array
    17	Memory Device
    18	32-Bit Memory Error Information
    19	Memory Array Mapped Address
    20	Memory Device Mapped Address
    21	Built-in Pointing Device
    22	Portable Battery
    23	System Reset
    24	Hardware Security
    25	System Power Controls
    26	Voltage Probe
    27	Cooling Device
    28	Temperature Probe
    29	Electrical Current Probe
    30	Out-of-Band Remote Access
    31	Boot Integrity Services (BIS) Entry Point
    32	System Boot Information
    33	64-Bit Memory Error Information
    34	Management Device
    35	Management Device Component
    36	Management Device Threshold Data
    37	Memory Channel
    38	IPMI Device Information
    39	System Power Supply
    40	Additional Information
    41	Onboard Devices Extended Information
    42	Management Controller Host Interface
    126	Inactive
    127	End-of-Table
    128-255	Available for system- and OEM- specific information
 

# 参考资料 #

http://en.wikipedia.org/wiki/System_Management_BIOS

http://en.wikipedia.org/wiki/Desktop_Management_Interface

http://www.joecen.com/2007/04/19/view-bios-operating-system-in-the-dmi-smbios-information/

Related posts:
Linux kernel启动参数
RedHat Linux 网络配置文件详解
Linux/Fedora17上DHCP和DNS服务器的配置方法和问题分析
更新Linux内核头文件(linux headers)