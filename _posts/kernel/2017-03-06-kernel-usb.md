# 1. USB #
## 1.1 Linux查看USB设备信息 ##
首先需要将usbfs挂载一下，然后才能查看。

	$ mount -t usbfs none /proc/bus/usb
	$ cat  /proc/bus/usb/devices

或者在文件（/etc/fstab）中添加如下这句：

	none  /proc/bus/usb  usbfs  defaults  0  0

查看到的信息，如下所示：

	T:  Bus=02 Lev=00 Prnt=00 Port=00 Cnt=00 Dev#=  1 Spd=12   MxCh= 3
	B:  Alloc=  0/900 us ( 0%), #Int=  0, #Iso=  0
	D:  Ver= 1.10 Cls=09(hub  ) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
	P:  Vendor=1d6b ProdID=0001 Rev= 3.00
	S:  Manufacturer=Linux 3.0.15 ohci_hcd
	S:  Product=s5p OHCI
	S:  SerialNumber=s5p-ohci
	C:* #Ifs= 1 Cfg#= 1 Atr=e0 MxPwr=  0mA
	I:* If#= 0 Alt= 0 #EPs= 1 Cls=09(hub  ) Sub=00 Prot=00 Driver=hub
	E:  Ad=81(I) Atr=03(Int.) MxPS=   2 Ivl=255ms
	
	T:  Bus=01 Lev=00 Prnt=00 Port=00 Cnt=00 Dev#=  1 Spd=480  MxCh= 3
	B:  Alloc=  0/800 us ( 0%), #Int=  0, #Iso=  0
	D:  Ver= 2.00 Cls=09(hub  ) Sub=00 Prot=00 MxPS=64 #Cfgs=  1
	P:  Vendor=1d6b ProdID=0002 Rev= 3.00
	S:  Manufacturer=Linux 3.0.15 ehci_hcd
	S:  Product=S5P EHCI Host Controller
	S:  SerialNumber=s5p-ehci
	C:* #Ifs= 1 Cfg#= 1 Atr=e0 MxPwr=  0mA
	I:* If#= 0 Alt= 0 #EPs= 1 Cls=09(hub  ) Sub=00 Prot=00 Driver=hub
	E:  Ad=81(I) Atr=03(Int.) MxPS=   4 Ivl=256ms

如何看懂这些信息呢？参见：kernel\Documentation\usb\proc_usb_info.txt

- T = 总线拓扑（Topology）结构（Lev, Prnt, Port, Cnt, 等），是指USB设备和主机之间的连接方式
- B = 带宽（Bandwidth）（仅用于USB主控制器）
- D = 设备（Device）描述信息
- P = 产品（Product）标识信息
- S = 字符串（String）描述符
- C = 配置（Config）描述信息 (* 表示活动配置)
- I = 接口（Interface）描述信息
- E = 端点（Endpoint）描述信息

一般格式：

- d = 十进制数
- x = 十六进制数
- s = 字符串

**拓扑信息**

	T:   Bus=dd Lev=dd Prnt=dd Port=dd Cnt=dd Dev#=ddd Spd=ddd MxCh=dd
	|    |      |      |       |       |      |        |       |__最大子设备
	|    |      |      |       |       |      |        |__设备速度（Mbps）
	|    |      |      |       |       |      |__设备编号
	|    |      |      |       |       |__这层的设备数
	|    |      |      |       |__此设备的父连接器/端口
	|    |      |      |__父设备号
	|    |      |__此总线在拓扑结构中的层次
	|    |__总线编号
	|__拓扑信息标志

**带宽信息**

	B:   Alloc=ddd/ddd us (xx%), #Int=ddd, #Iso=ddd
	|    |                        |         |__同步请求编号
	|    |                        |__中断请求号
	|    |__分配给此总线的总带宽
	|__带宽信息标志

**设备描述信息和产品标识信息**

	D:   Ver=x.xx Cls=xx(sssss) Sub=xx Prot=xx MxPS=dd #Cfgs=dd
	|    |        |             |      |       |        |__配置编号
	|    |        |             |      |       |______缺省终端点的最大包尺寸
	|    |        |             |      |__设备协议
	|    |        |             |__设备子类型
	|    |        |__设备类型
	|    |__设备USB版本
	|__设备信息标志编号#1
	P:   Vendor=xxxx ProdID=xxxx Rev=xx.xx
	|       |                    |                    |__产品修订号
	|       |                    |__产品标识编码
	|       |__制造商标识编码
	|__设备信息标志编号#2

**串描述信息**

	S:   Manufacturer=ssss
	|    |__设备上读出的制造商信息
	|__串描述信息
	S:   Product=ssss
	|    |__设备上读出的产品描述信息，对于USB主控制器此字段为"USB *HCI Root Hub"
	|__串描述信息
	S:   SerialNumber=ssss
	|    |__设备上读出的序列号，对于USB主控制器它是一个生成的字符串，表示设备标识
	|__串描述信息

**配置描述信息**

	C:   #Ifs=dd Cfg#=dd Atr=xx MPwr=dddmA
	|     |      |       |      |__最大电流（mA）
	|     |      |       |__属性
	|     |      |__配置编号
	|     |__接口数
	|__配置信息标志

**接口描述信息**(可为多个)

	I:   If#=dd Alt=dd #EPs=dd Cls=xx(sssss) Sub=xx Prot=xx Driver=ssss
	|    |      |      |       |             |      |       |__驱动名
	|    |      |      |       |             |      |__接口协议
	|    |      |      |       |             |__接口子类
	|    |      |      |       |__接口类
	|    |      |      |__端点数
	|    |      |__可变设置编号
	|    |__接口编号
	|__接口信息标志

**端点描述信息**

	E:   Ad=xx(s) Atr=xx(ssss) MxPS=dddd Ivl=dddms
	|    |         |            |         |__间隔
	|    |         |            |__终端点最大包尺寸
	|    |         |__属性(终端点类型)
	|    |__终端点地址(I=In,O=Out)
	|__终端点信息标志

## 1.2 Linux查看USB端点解析 ##

__u8 bEndpointAddress; //端点地址：0～3位是端点号，第7位是方向(0-OUT,1-IN)

端点地址:总共8位0,1,2,3四位表示端点号，第7位表示端点方向

那么由这5位可以确定32个端点地址.

其中输入端点0-15输出端点0-15

Out endpoint for all omron health devices,

所有Omron健康设备的输出端点地址(共8位,包括端点号,端点类型和端点方向)

static const uint32_t OMRON_OUT_ENDPT = 0x02;

In endpoint for all omron health devices,

所有Omron健康设备的输入端点地址(共8位,包括端点号,端点类型,和端点方向)

static const uint32_t OMRON_IN_ENDPT = 0x81;

我们和设备通信的时候,不是使用端点号,端点号不能唯一确定一个管道,而是使用端点地址,端点地址中的端点号和端点方向,可以唯一确定一个管道pipe.


 0x81 端点的地址 1000 0001

 D7 表示传输方向 1 为输入 

 D6~D4 reserved

 D3~D0 为端点号 端点号为 01
  也就是说 1 号端点,输入端点

//////////////////////////////////////////////////////////////

0x02 端点的地址 0000 0010
D7 表示传输方向 1 为输入

 D6~D4 reserved 

D3~D0 为端点号 端点号为 2
端点号为 2,输出端点

USB 通讯的最基本形式是通过某些称为 端点 的. 一个 USB 端点只能在一个方向承载数据, 或者从主机到设备(称为输出端点)或者从设备到主机(称为输入端点). 端点可看作一个单向的管道.

一个 USB 端点可是 4 种不同类型的一种, 它来描述数据如何被传送:

CONTROL
控制端点被用来允许对 USB 设备的不同部分存取. 通常用作配置设备, 获取关于设备的信息, 发送命令到设备, 或者获取关于设备的状态报告. 这些端点在尺寸上常常较小. 每个 USB 设备有一个控制端点称为"端点 0", 被 USB 核用来在插入时配置设备. 这些传送由 USB 协议保证来总有足够的带宽使它到达设备.

INTERRUPT
中断端点传送小量的数据, 以固定的速率在每次 USB 主请求设备数据时. 这些端点对 USB 键盘和鼠标来说是主要的传送方法. 它们还用来传送数据到 USB 设备来控制设备, 但通常不用来传送大量数据. 这些传送由 USB 协议保证来总有足够的带宽使它到达设备.

BULK
块端点传送大量的数据. 这些端点常常比中断端点大(它们一次可持有更多的字符). 它们是普遍的, 对于需要传送不能有任何数据丢失的数据. 这些传送不被 USB 协议保证来一直使它在特定时间范围内完成. 如果总线上没有足够的空间来发送整个 BULK 报文, 它被分为多次传送到或者从设备. 这些端点普遍在打印机, 存储器, 和网络设备上.

ISOCHRONOUS
同步端点也传送大量数据, 但是这个数据常常不被保证它完成. 这些端点用在可以处理数据丢失的设备中, 并且更多依赖于保持持续的数据流. 实时数据收集, 例如音频和视频设备, 一直都使用这些端点.

控制和块端点用作异步数据传送, 无论何时驱动决定使用它们. 中断和同步端点是周期性的. 这意味着这些端点被设置来连续传送数据在固定的时间, 这使它们的带宽被 USB 核所保留.

USB 端点在内核中使用结构 struct usb_host_endpoint 来描述. 这个结构包含真实的端点信息在另一个结构中, 称为 struct usb_endpoint_descriptor. 后者包含所有的 USB-特定 数据, 以设备自身特定的准确格式. 驱动关心的这个结构的成员是:

bEndpointAddress
这是这个特定端点的 USB 地址. 还包含在这个 8-位 值的是端点的方向. 位掩码 USB_DIR_OUT 和 USB_DIR_IN 可用来和这个成员比对, 来决定给这个端点的数据是到设备还是到主机.

bmAttributes
这是端点的类型. 位掩码 USB_ENDPOINT_XFERTYPE_MASK 应当用来和这个值比对, 来决定这个端点是否是 USB_ENDPOINT_XFER_ISOC, USB_ENDPOINT_XFER_BULK, 或者是类型 USB_ENDPOINT_XFER_INT. 这些宏定义了同步, 块, 和中断端点, 相应地.

wMaxPacketSize
这是以字节计的这个端点可一次处理的最大大小. 注意驱动可能发送大量的比这个值大的数据到端点, 但是数据会被分为 wMaxPakcetSize 的块, 当真正传送到设备时. 对于高速设备, 这个成员可用来支持端点的一个高带宽模式, 通过使用几个额外位在这个值的高位部分. 关于如何完成的细节见 USB 规范.

bInterval
如果这个端点是中断类型的, 这个值是为这个端点设置的间隔, 即在请求端点的中断之间的时间. 这个值以毫秒表示.


## 1.3 传输速率 ##
在USB数据通信的过程中，总线上传输的并不只是真正需要的数据信息，还要包括诸如同步信号、类型标识、校验码、握手信号等各种协议信息。因此实际数据传输的速率根本没有可能达到总线传输的极限速度480 Mbps。且对不同的传输类型，存在不同的协议开销。如在USB1.1协议下规定的每毫秒1帧中，对一个设备的中断传输只能进行一次，考虑中断传输的数据包为64Byte，故可算出这种传输的最大速度只有64 kB/s。
    
对USB2.0的情况，由于采用了微帧结构，每帧分为8个微帧，且中断传输在每个微帧下可以传输3个数据包，而每包的数据也增加到1024个字节，故可以算出USB2.0的中断传输的最大速度提高到8×3×1024 B/ms=24 MB/s。尽管与USB1.1的64 KB/s相比提高很大，却仍与480Mbp(60 MB/s)相差很远。

# 2. V4L2 框架 #

![](/kvm_blog/files/kernel/v4l2.jpg)

## 2.1 V4l2 介绍
http://www.cnblogs.com/hzhida/archive/2012/05/29/2524397.html

众所周知，linux中可以采用灵活的多层次的驱动架构来对接口进行统一与抽象，最低层次的驱动总是直接面向硬件的，而最高层次的驱动在linux中被划分为“面向字符设备、面向块设备、面向网络接口”三大类来进行处理，前两类驱动在文件系统中形成类似文件的“虚拟文件”，又称为“节点node”，这些节点拥有不同的名称代表不同的设备，在目录/dev下进行统一管理，系统调用函数如open、close、read等也与普通文件的操作有相似之处，这种接口的一致性是由VFS（虚拟文件系统层）抽象完成的。面向网络接口的设备仍然在UNIX/Linux系统中被分配代表设备的名称（如eth0），但是没有映射入文件系统中，其驱动的调用方式也与文件系统的调用open、read等不同。

video4linux2(V4L2)是Linux内核中关于视频设备的中间驱动层，向上为Linux应用程序访问视频设备提供了通用接口，向下为linux中设备驱动程序开发提供了统一的V4L2框架。在Linux系统中，V4L2驱动的视频设备（如摄像头、图像采集卡）节点路径通常为/dev中的videoX，V4L2驱动对用户空间提供“字符设备”的形式，主设备号为81，对于视频设备，其次设备号为0-63。除此之外，次设备号为64-127的Radio设备，次设备号为192-223的是Teletext设备,次设备号为224-255的是VBI设备。由V4L2驱动的Video设备在用户空间通过各种ioctl调用进行控制，并且可以使用mmap进行内存映射。

要想了解 V4l2 有几个重要的文档是必须要读的：

- 源码Documentation/video4linux目录下的V4L2-framework.txt和videobuf
- V4L2的官方API文档V4L2 API Specification
- 源码drivers/media/video目录下的sample程序vivi.c（虚拟视频驱动程序，此代码模拟一个真正的视频设备V4L2 API）。

V4l2可以支持多种设备,它可以有以下几种接口:

- 视频采集接口(video capture interface):这种应用的设备可以是高频头或者摄像头.V4L2的最初设计就是应用于这种功能的.

- 视频输出接口(video output interface):可以驱动计算机的外围视频图像设备--像可以输出电视信号格式的设备.

- 直接传输视频接口(video overlay interface):它的主要工作是把从视频采集设备采集过来的信号直接输出到输出设备之上,而不用经过系统的CPU.

- 视频间隔消隐信号接口(VBI interface):它可以使应用可以访问传输消隐期的视频信号.

- 收音机接口(radio interface):可用来处理从AM或FM高频头设备接收来的音频流.

## 2.2 UVC摄像头代码解析 ##
http://blog.csdn.net/ropenyuan/article/details/41014423

http://blog.csdn.net/g_salamander/article/details/8107692

Andrew附：值得注意的是，内核底层驱动程序的支持情况往往是我们关心的。推荐这篇博文《Linux 下摄像头驱动支持情况》  http://weijb0606.blog.163.com/blog/static/131286274201063152423963/   