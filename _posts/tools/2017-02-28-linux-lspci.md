# lspci命令详解 #
说明：lspci 是一个用来显示系统中所有PCI总线设备或连接到该总线上的所有设备的工具。

## 1. 命令格式 ##


-  -v  使得 lspci 以冗余模式显示所有设备的详细信息。  
-  -vv使得 lspci 以过冗余模式显示更详细的信息 (事实上是 PCI 设备能给出的所有东西)。这些数据的确切意义没有
-     在此手册页中解释，如果你想知道更多，请参照 /usr/include/linux/pci.h 或者 PCI 规范。  
-  -n  以数字形式显示 PCI 生产厂商和设备号，而不是在 PCI ID 数据库中查找它们。  
-  -x  以十六进制显示 PCI 配置空间 (configuration space) 的前64个字节映像 (标准头部信息)。此参数对调试驱动和
       lspci 本身很有用。  
-  -xxx   以十六进制显示所有 PCI 配置空间的映像。此选项只有 root 可用，并且很多 PCI 设备在你试图读取配置空间
     的未定义部分时会崩溃 (此操作可能不违反PCI标准，但是它至少非常愚蠢)。  
-  -b  以总线为中心进行查看。显示所有 IRQ 号和记忆体地址，就像 PCI 总线上的卡看到的一样，而不是核心看到
       的内容。  
-  -t   以树形方式显示包含所有总线、桥、设备和它们的连接的图表。  
-  -s  [[<bus>]:][<slot>][.[<func>]]仅显示指定总线、插槽上的设备或设备上的功能块信息。设备地址的任何部分都可
       以忽略，或以「*」代替 (意味著所有值)。所有数字都是十六进制。  
       例如：「0：」指的是在0号总线上的所有设备；
       「0」指的是在任意总线上0号设备的所有功能块；
       「0.3」选择 了所有总线上0号设备的第三个功能块；
       「.4」则是只列出每一设备上的第四个功能块。  
-  -d [<vendor>]:[<device>] 只显示指定生产厂商和设备 ID 的设备。 这两个 ID 都以十六进制表示，可以忽略或者以「*」
       代替 (意味著所有值)。  
-  -i <file>使用 <file> 作为 PCI ID 数据库而不是使用预设的 /usr/share/hwdata/pci.ids。  
-  -p 目录，使用目录作为包含 PCI 总线信息的目录而不是使用预设的目录 /proc/bus/pci。  
-  -m 以机器可读的方式转储 PCI 设备数据 (支持两种模式：普通和冗余)，便於稿本解析。  
-  -M 使用总线映射模式，这种模式对总线进行全面地扫描以查明总线上的所有设备，包括配置错误的桥之后的设备。请
       注意，此操作只应在调试时使 用，并可能造成系统崩溃 (只在设备有错误的时候，但是不幸的是它们存在)，此命令
       只有 root 可以使用。同时，在不直接接触硬体的 PCI 访问模式中使用 -M 参数没有意义，因为显示的结果 (排除 lspci 
       中的 bug 的影响) 与普通的列表模式相同。  
-  --version 显示 lspci 的版本。这个选项应当单独使用。

## 2.常用命令 ##
lspci -Dn -s $bdf  
-D 选项表示在输出信息中显示设备的 domain  
-n 选项表示用数字的方式显示设备的 vendor ID 和 device ID  
-s 选项表示仅显示后面指定的一个设备的信息  

lspci -k -s $bdf  
-k 表示输出信息中显示正在使用的驱动和内核中可以支持该设备的模板。

lspci -v -s $bdf | grep SR-IOV  
查看PCI设备是否支持 SR-IOV 功能

lspci -nvv -s $bdf
查看该 bdf 的 device id, 像下面的 203f 就是设备 ID.

	fa:00.0 0604: 8086:203f (rev 04) (prog-if 00 [Normal decode])
	        Physical Slot: 0-2
	        Control: I/O+ Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr+ Stepping- SERR+ FastB2B- DisINTx+
	        Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	        Latency: 0


## 3. PCIE
ref:

https://superuser.com/questions/693964/can-i-find-out-if-pci-e-slot-is-1-0-2-0-or-3-0-in-linux-terminal

http://www.edn.com/electronics-news/4380071/What-does-GT-s-mean-anyway-

https://zh.wikipedia.org/zh-cn/PCI_Express

### 3.1 PCIe slot 版本识别
PCIE 有三个版本，分别是 PCIe 1.1, PCIe 2.0, PCIe 3.0

You can use the "dmidecode" command to give an in depth list of all the hardware on the system and then view that. I did a "quick and dirty" command to show the pertinent bit as follows:

dmidecode | grep "PCI"
Which returned

PCI is supported
Type: x16 PCI Express 2 x8
Type: x8 PCI Express 2 x4
Type: x8 PCI Express 2 x4
Type: x8 PCI Express 2 x4
Type: 32-bit PCI

Using lspci -vv, you can get the transfer rate and compare it with the transfer rate specified for the revisions. A sample output would read:

### 3.2 speed rate

	$ lspci -vv | grep -E 'PCI bridge|LnkCap'
	00:02.0 PCI bridge: NVIDIA Corporation C51 PCI Express Bridge (rev a1) (prog-if 00 [Normal decode])
	                LnkCap: Port #2, **Speed 2.5GT/s**, Width x1, ASPM L0s L1, Latency L0 <512ns, L1 <4us

### 3.2 GT/s vs Gb/s
Most of us are used to seeing bus speeds specified in Gbps, or gigabits per second, but GT/s stands for gigatransfers per second. What’s the difference?
The difference has to do with the encoding of the data. Because PCIe is a serial bus with the clock embedded in the data, it needs to ensure that enough level transitions (1 to 0 and 0 to 1) occur for a receiver to recover the clock. To increase level transitions, PCIe uses “8b/10b” encoding, where every eight bits are encoded into a 10-bit symbol that is then decoded at the receiver. Thus, the bus needs to transfer 10 bits to send 8 bits of encoded data.

2.5GT/s = 2Gb/s = 2Gbps

## 4. 实例 ##

实例1：不必加上任何选项，就能够显示出目前的硬件配备

    # lspci
    // 主板芯片
    Host bridge: Intel Corporation 3200/3210 Chipset DRAM Controller  
    // USB控制器
    00:19.0 Ethernet controller: Intel Corporation 82566DM-2 Gigabit Network Connection (rev 02)
    00:1a.0 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #4 (rev 02)
    00:1a.1 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #5 (rev 02)
    00:1a.2 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #6 (rev 02)
    00:1a.7 USB Controller: Intel Corporation 82801I (ICH9 Family) USB2 EHCI Controller #2 (rev 02)  
    //接口插槽
    00:1c.0 PCI bridge: Intel Corporation 82801I (ICH9 Family) PCI Express Port 1 (rev 02) 
    00:1c.4 PCI bridge: Intel Corporation 82801I (ICH9 Family) PCI Express Port 5 (rev 02)
    00:1d.0 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #1 (rev 02)
    00:1d.1 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #2 (rev 02)
    00:1d.2 USB Controller: Intel Corporation 82801I (ICH9 Family) USB UHCI Controller #3 (rev 02)
    00:1d.7 USB Controller: Intel Corporation 82801I (ICH9 Family) USB2 EHCI Controller #1 (rev 02)
    00:1e.0 PCI bridge: Intel Corporation 82801 PCI Bridge (rev 92)
    00:1f.0 ISA bridge: Intel Corporation 82801IR (ICH9R) LPC Interface Controller (rev 02)
    00:1f.2 IDE interface: Intel Corporation 82801IR/IO/IH (ICH9R/DO/DH) 4 port SATA IDE Controller (rev 02)
    00:1f.3 SMBus: Intel Corporation 82801I (ICH9 Family) SMBus Controller (rev 02)
    00:1f.5 IDE interface: Intel Corporation 82801I (ICH9 Family) 2 port SATA IDE Controller (rev 02)
    //显卡
    02:00.0 VGA compatible controller: Matrox Graphics, Inc. MGA G200e [Pilot] ServerEngines (SEP1) (rev 02) 
    //网卡 
    03:02.0 Ethernet controller: Intel Corporation 82541GI Gigabit Ethernet Controller (rev 05) 
 
实例2：查看一般详细信息

    # lspci -v 00:00.0 Host bridge: Intel Corporation 3200/3210 Chipset DRAM ControllerSubsystem: Intel Corporation Unknown device 34d0Flags: bus master, fast devsel, latency 0Capabilities: [e0] Vendor Specific Information00:19.0 Ethernet controller: Intel Corporation 82566DM-2 Gigabit Network Connection (rev 02)Subsystem: Intel Corporation Unknown device 34d0Flags: bus master, fast devsel, latency 0, IRQ 50Memory at e1a00000 (32-bit, non-prefetchable) [size=128K]Memory at e1a20000 (32-bit, non-prefetchable) [size=4K]
        I/O ports at 20e0 [size=32]Capabilities: [c8] Power Management version 2Capabilities: [d0] Message Signalled Interrupts: 64bit+ Queue=0/0 Enable+Capabilities: [e0] #13 [0306]
 
实例3：查看网卡详细信息

    # lspci -s 03:02.0 -vv  //-s后面接的是每个设备的总线、插槽与相关函数功能
    03:02.0 Ethernet controller: Intel Corporation 82541GI Gigabit Ethernet Controller (rev 05)Subsystem: Intel Corporation Unknown device 34d0Control: I/O+ Mem+ BusMaster+ SpecCycle- MemWINV+ VGASnoop- ParErr+ Stepping- SERR+ FastB2B-Status: Cap+ 66MHz+ UDF- FastB2B- ParErr- DEVSEL=medium >TAbort- <tabort- <mabort- >SERR- <perr-Latency: 32 (63750ns min), Cache Line Size: 64 bytes   Interrupt: pin A routed to IRQ 209Region 0: Memory at e1920000 (32-bit, non-prefetchable) [size=128K]Region 1: Memory at e1900000 (32-bit, non-prefetchable) [size=128K]Region 2: I/O ports at 1000 [size=64]Expansion ROM at fffe0000 [disabled] [size=128K]Capabilities: [dc] Power Management version 2Flags: PMEClk- DSI+ D1- D2- AuxCurrent=0mA PME(D0+,D1-,D2-,D3hot+,D3cold+)Status: D0 PME-Enable- DSel=0 DScale=1 PME-Capabilities: [e4] PCI-X non-bridge device
    Command: DPERE- ERO+ RBC=512 OST=1Status: Dev=00:00.0 64bit- 133MHz- SCD- USC- DC=simple DMMRBC=2048 DMOST=1 DMCRS=8 RSCEM- 266MHz- 533MHz-

 
## 4.附录 ##
附录1：为了能使用这个命令所有功能，你需要有 linux 2.1.82 或以上版本，支持 /proc/bus/pci 接口的核心。在旧版本核心中，PCI工具必须使用只有root才能执行的直接硬体访问，而且总是出现竞争状况以及其他问题。
如果你要报告 PCI 设备驱动中，或者是 lspci 自身的 bugs，请在报告中包含 “lspci -vvx” 的输出。

附录2：CentOS bash: lspci: command not found解决方法
大多使用/sbin/lspci即可，我发现我的系统中/sbin下也没有。使用yum install lspci显示没有这个包。

    # yum whatprovides */lspciLoaded plugins: fastestmirror
    Loading mirror speeds from cached hostfile
     * base: mirrors.grandcloud.cn
     * extras: mirrors.163.com* updates: mirrors.grandcloud.cn
    base/filelists  | 3.6 MB 00:16
    extras/filelists_db  | 241 kB 00:00
    updates/filelists_db   | 2.4 MB 00:19
    pciutils-3.1.7-5.el5.x86_64 : PCI bus related utilities  
    //这里显示的pciutils-3.1.7-5.el5.x86_64Repo: baseMatched from:Filename: /sbin/lspci
    pciutils-3.1.7-3.el5.x86_64 : PCI bus related utilities.Repo: installed
    Matched from:Filename: /sbin/lspci