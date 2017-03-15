# 1. Summary #
     
热插拔即“带电插拔”，指可以在电脑运行时（不关闭电源）插上或拔除硬件。实现热插拔需要有以下几个方面支持：总线电气特性、主板BIOS、操作系统和设备驱动。那么我们只要确定环境符合以上特定的环境，就可以实现热插拔。系统总线支持部分热插拔技术。驱动方面，针对Windows NT,Novell的Netware,SCO UNIX的驱动都把热插拔功能整合了进去，只要选择针对以上操作系统的驱动，实现热插拔的最后一个要素就具备了。目前在服务器硬件中，可实现热插拔的部件主要有 SATA 硬盘（IDE不支持热插拔）、CPU、内存、风扇、USB、网卡等。在KVM虚拟化环境中，在不关闭客户机的情况下，也可以对客户机的设备进行热
插拔。目前，KVM对热插拔的支持还不够完善，主要支持PCI设备和CPU的热插拔，也可以通过 ballooning间接实现内存的热插拔。

## 1.1 PCI 设备热插拔 ##
PCI设备的热插拔，主要需要如下几个方面的支持

(1) BIOS
      
QEMU/KVM 默认使用 SeaBIOS作为客户机的 BIOS，该 BIOS 文件路径一般为 /usr/local/share/qemu/bios.bin，目前默认的BIOS 已经可以支持 PCI 设备的热插拔。

(2) PCI 总线

物理硬件中必须有 VT-d 的支持，且现在的 PCI、 PCIe总线都支持设备的热插拔

(3) 客户机操作系统

多数流行的 Linux 和 Windows 操作系统都支持设备的热插拔。可以在客户机的 Linux 系统的内核配置文件中看到一些相关的配置

	CONFIG_HOTPLUG=y
	CONFIG_HOTPLUG_PCI_PCIE=y
	CONFIG_HOTPLUG_PCI=y
	CONFIG_HOTPLUG_PCI_FAKE=y
	CONFIG_HOTPLUG_PCI_ACPI=y
	CONFIG_HOTPLUG_PCI_ACPI_IBM=y

(4) 客户机中的驱动程序
一些网卡驱动、SATA或SAS磁盘驱动、USB2.0、USB3.0驱动都支持设备的热插拔。注意在一些较旧的 Linux 系统中需要加载 acpiphp
这个模块后才支持设备的热插拔，否则热插拔完全不会对客户机系统生效；
可以直接在 Qemu monitor 下操作：

- 将一个 PCI设备添加到客户机中（设置ID为 mydevice ）
     
	device_add pci-assign,host=$bdf,id=mydevice
- 将一个设备从客户机中动态移除，在 monitor中命令如下：
     
	device_del mydevice

这个 mydevice ，可以在使用 info  pci 查看

## 1.2 PCI 设备热插拔示例 ##
    
(1) 网卡的热插拔 
        
a. 启动一个客户机    

    qemu-system-x86_64 rhel6u3.img -m 1024 -smp 2 -net none

b. 选择并隐藏网卡设备

    lspci -s $bdf
    ./pci_stub.sh -h $bdf
        
c. 切换到 Qemu monitor 中，将网卡动态添加到客户机中，命令如下所示。一般可以用 Alt+Ctrl+2 快捷键进入到 monitor中，也可以在启动时添加参数 “-monitor stdio" 将 monitor定向到当前终端的标准输入输出中直接进行操作。

	(qemu) device_add pci-assign,host=$bdf,id=mynic
        
d. 查看客户机的 PCI 设备信息
           
	(qemu) info pci
        
e. 在客户机中检查动态添加和网卡工作情况，命令行如下：
           
	lspci | grep Eth
    ethtool -i eth2
    ifconfig eth2
    ping 192.168.199.103 -c 1 -I eth2
    
	由以上输出信息可知，动态添加的客户机中唯一的网卡设备，其网络接口名称为 eth2 ，它的网络连接是通畅的。
        
f. 将刚添加的网卡动态地从客户机中移除，命令行如下：
     
	(qemu) device_del mynic

    
(2) USB设备热插拔
          
USB 设备是现代计算机系统中比较重要的一类设备，包括USB的键盘和鼠标、U盘等设备。USB设备也可以像普通 PCI 设备那样进行 VT-d 设备进行直接分配，而在热插拔方面也是类似的。qemu-kvm 默认没有像客户机提供 USB 总线，需要在客户机的 qemu-kvm 命令行中添加 -usb 参数（或是 -device piix3-usb-uhci）来提供客户机中的USB总线。
        
a. 查看宿主机中的 USB设备情况，然后启动一个带有USB总线控制器的客户机，命令行如下：
           
	# lsusb
    # qemu-system-x86_64 rhel6u3.img -m 1024 -smp 2 -net none
        
b. 切换到 Qemu monitor 窗口，动态添加 SanDisk 的 U盘给客户机，使用 usb_add命令行如下：
           
	# usb_add host:002.004
    或
    # usb_add host:0781:5567
    
c. 在客户机中查看添加的 USB 设备

    # lsusb
    # fdisk -l /dev/sdb
    
d. 在 Qemu monitor 中查看 USB设备，然后动态移除 USB 设备
    
    (qemu) info usb
    (qemu) usb_del 0.2
    (qemu) info usb
        
(3) SATA硬盘的热插拔
        
本小节的示例中， 宿主机从一台机器上的SAS硬盘启动，然后将SATA硬盘动态添加给客户机使用，接着动态移除该硬盘。
        
a. 检查宿主机系统，得到需要动态热插拔的SATA硬盘，并将其隐藏

	# lspci | grep SATA
	# lspci | grep SAS
	# df -h
	# ll /dev/disk/by-path/pci-0000\:16\:00.0-sas-0x12210000000000-lun-0
	# ll /dev/disk/by-path/pci-0000\:00\:1f.2-scsi-0\:0\:0\:0\:0
	# lspci -k -s 00:1f.2
	# ./pci_stub.sh -h 00:1f.2
	#  lspci -k -s 00:1f.2
        
b. 启动一个客户机，命令行如下：
            
	qemu-system-x86_64 rhel6u3.img -m 1024 -smp 2 -net nic -net tap
        
c. 在 Qemu Monitor 中，动态添加该 SATA 硬盘
            
	(qemu) device_add pci-assign,host=00:1f.2,id=sata,addr=0x6
    (qemu) info pci
        
d. 在客户机中查看动态的 SATA 硬盘
            
	# fdisk -l /dev/sdb
    # lspci -k -s 00:06.0
        
e. 动态移除 SATA 硬盘
            
	(qemu) device_del sata

## 1.3 CPU和内存的热移除 ##
     
CPU和内存的热插拔是RAS的一个重要特性，在非虚拟化环境中，只有较少的 x86 服务器硬件支持CPU和内存热插拔。在操作系统方面，拥有较新内核的 Linux 系统（如 RHEL6.3 ）等已经支持 CPU和内存的热插拔，在其内核配置文件中可以看到类似如下选项：

     CONFIG_HOTPLUG=y
     CONFIG_MEMORY_HOTPLUG=y
     CONFIG_CPU_HOTPLUG=y
     CONFIG_ARCH_ENABLE_MEMORY_HOTPLUG=y
     CONFIG_ARCH_ENABLE_MEMORY_HOTREMOVE=y
     CONFIG_ACPI_HOTPLUG_CPU=y
     CONFIG_ACPI_HOTPLUG_MEMORY=y

(1) 启动客户机
         
	qemu-system-x86_64 rhel6u3.img -m 1024 -smp 2,maxvcpus=8 -net nic -net tap
         这就是客户机启动时使用的两个 vCPU，而最多支持客户机动态添加到 8 个vCPU

(2) 在客户机中检查 CPU 的状态，如下：
        
	ls /sys/devices/system/cpu/

(3) 通过 QEMU monitor  中的 “ cpu_set n online" 命令为客户机添加 n 个 VCPU，如下：
        
	(qemu) cpu_set 4 online      动态添加 4个 vCPU
    (qemu) cpu_set 4 offline      动态移除 4个 vCPU

(4) 检查客户机中 vCPU 的数量是否与预期的相符，如果看到 /sys/devices/system/cpu/ 目录下CPU的数量增加（或减少）了 n 个，则表示操作成功 ，另外如果是动态添加CPU，客户机中新增的CPU没有自动上线工作，可以用下面命令使其进入可用状态。

     echo 1 > /sys/devices/system/cpu/cpu2/online

# 1.4 Test NIC hotplug #
Test NIC hotplug
Initial Condition:

Prepare one Host that is Knights Landing Server and Later Server.
Test steps:

1. Create guest and assign NIC.
   
		# xl create xen-rhel7.conf
  
2. Hide a NIC.
   
		# lspci –s 06:10.1
		# xl pci-assignable-add 06:10.1

3. Add NIC to VM.
	
		# xl pci-attach domid $bdf
 
4. Check NIC status.

		# lspci –s 00:06.1
		# ethtool –I eth2
		# ping 192.168.199.98 –I eth2 –c 1
 
5. Delete NIC from VM.
   
		# xl pci-detach domid $bdf
		# lspci
