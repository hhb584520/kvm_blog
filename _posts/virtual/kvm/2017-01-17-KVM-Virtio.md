# 1.半虚拟化驱动 #
## 1.1 virtio概述 ##

KVM是必须使用硬件虚拟化辅助技术（如Intel VT-x、AMD-V）的hypervisor，在CPU运行效率方面有硬件支持，其效率是比较高的；在有Intel EPT特性支持的平台上，内存虚拟化的效率也较高。QEMU/KVM提供了全虚拟化环境，可以让客户机不经过任何修改就能运行在KVM环境中。不过，KVM在I/O虚拟化方面，传统的方式是使用QEMU纯软件的方式来模拟I/O设备（如第4章中提到模拟的网卡、磁盘、显卡等等），其效率并不非常高。在KVM中，可以在客户机中使用半虚拟化驱动（Paravirtualized Drivers，PV Drivers）来提高客户机的性能（特别是I/O性能）。目前，KVM中实现半虚拟化驱动的方式是采用了virtio这个Linux上的设备驱动标准框架。

## 1.2 QEMU模拟I/O设备的基本原理和优缺点 ##

QEMU纯软件方式模拟现实世界中的I/O设备的基本过程模型如图5-1所示。

![](/kvm_blog/img/qemu-emulated-io.jpg)

使用QEMU模拟I/O的情况下:

(1) 当客户机中的设备驱动程序（device driver）发起I/O操作请求之时，KVM模块中的I/O操作捕获代码会拦截这次I/O请求，然后经过处理后将本次I/O请求的信息存放到I/O共享页，并通知用户控件的QEMU程序。

(3) QEMU模拟程序获得I/O操作的具体信息之后，交由硬件模拟代码来模拟出本次的I/O操作.

(4) 完成之后，将结果放回到I/O共享页，并通知KVM模块中的I/O操作捕获代码。

(5) 最后，由KVM模块中的捕获代码读取I/O共享页中的操作结果，并把结果返回到客户机中。

当然，这个操作过程中客户机作为一个QEMU进程在等待I/O时也可能被阻塞。另外，当客户机通过DMA（Direct Memory Access）访问大块I/O之时，QEMU模拟程序将不会把操作结果放到I/O共享页中，而是通过内存映射的方式将结果直接写到客户机的内存中去，然后通过KVM模块告诉客户机DMA操作已经完成。

QEMU模拟I/O设备的方式，其优点是可以通过软件模拟出各种各样的硬件设备，包括一些不常用的或者很老很经典的设备（如4.5节中提到RTL8139的网卡），而且它不用修改客户机操作系统，就可以实现模拟设备在客户机中正常工作。在KVM客户机中使用这种方式，对于解决手上没有足够设备的软件开发及调试有非常大的好处。而它的缺点是，每次I/O操作的路径比较长，有较多的VMEntry、VMExit发生，需要多次上下文切换（context switch），也需要多次数据复制，所以它的性能较差。

## 1.3 Virtio的基本原理和优缺点 ##

Virtio最初由澳大利亚的一个天才级程序员Rusty Russell编写，是一个在hypervisor之上的抽象API接口，让客户机知道自己运行在虚拟化环境中，从而与hypervisor根据 virtio 标准协作，从而在客户机中达到更好的性能（特别是I/O性能）。目前，有不少虚拟机都采用了virtio半虚拟化驱动来提高性能，如KVM和Lguest[1]。
QEMU/KVM中，Virtio的基本结构框架如图5-2所示。

![](/kvm_blog/img/qemu-kvm-virtio.jpg)

其中前端驱动（frondend，如virtio-blk、virtio-net等）是在客户机中存在的驱动程序模块，而后端处理程序（backend）是在QEMU中实现的[2]。在这前后端驱动之间，还定义了两层来支持客户机与QEMU之间的通信。其中，“virtio”这一层是虚拟队列接口，它在概念上将前端驱动程序附加到后端处理程序。一个前端驱动程序可以使用0个或多个队列，具体数量取决于需求。例如，virtio-net网络驱动程序使用两个虚拟队列（一个用于接收，另一个用于发送），而virtio-blk块驱动程序仅使用一个虚拟队列。虚拟队列实际上被实现为跨越客户机操作系统和hypervisor的衔接点，但它可以通过任意方式实现，前提是客户机操作系统和virtio后端程序都遵循一定的标准，以相互匹配的方式实现它。而virtio-ring实现了环形缓冲区（ring buffer），用于保存前端驱动和后端处理程序执行的信息，并且它可以一次性保存前端驱动的多次I/O请求，并且交由后端去动去批量处理，最后实际调用宿主机中设备驱动实现物理上的I/O操作，这样做就可以根据约定实现批量处理而不是客户机中每次I/O请求都需要处理一次，从而提高客户机与hypervisor信息交换的效率。
Virtio半虚拟化驱动的方式，可以获得很好的I/O性能，其性能几乎可以达到和native（即：非虚拟化环境中的原生系统）差不多的I/O性能。所以，在使用KVM之时，如果宿主机内核和客户机都支持virtio的情况下，一般推荐使用virtio达到更好的性能。当然，virtio的也是有缺点的，它必须要客户机安装特定的Virtio驱动使其知道是运行在虚拟化环境中，且按照Virtio的规定格式进行数据传输，不过客户机中可能有一些老的Linux系统不支持virtio和主流的Windows系统需要安装特定的驱动才支持Virtio。不过，较新的一些Linux发行版（如RHEL 6.3、Fedora 17等）默认都将virtio相关驱动编译为模块，可直接作为客户机使用virtio，而且对于主流Windows系统都有对应的virtio驱动程序可供下载使用。

**Legacy**

KVM同应用程序(Qemu)的交互接口为/dev/kvm，通过open以及ioctl系统调用可以获取并操作KVM抽象出来的三个对象，Guest的虚拟处理器(fd_vcpu[N]), Guest的地址空间(fd_vm), KVM本身(fd_kvm)。其中每一个Guest可以含有多个vcpu，每一个vcpu对应着Host系统上的一个线程。

Qemu启动Guest系统时，通过/dev/kvm获取fd_kvm和fd_vm，然后通过fd_vm将Guest的“物理空间”mmap到Qemu进程的虚拟空间，并根据配置信息创建vcpu[N]线程，返回fd_vcpu[N]。然后Qemu将操作fd_vcpu在其自己的进程空间mmap一块KVM的数据结构区域。该数据结构(下图中的shared)用于同kvm.ko交互，包含Guest的IO信息，如端口号，读写方向，内存地址等。Qemu通过这些信息，调用虚拟设备注册的回调函数来模拟设备的行为，并将Guest IO请求换成系统请求发送给Host系统。由于Guest的地址空间已经映射到Qemu的进程空间里面，Qemu的虚拟设备逻辑可以很方便的存取Guest地址空间里面的数据。三个对象之间的关系如下图所示：

![](/kvm_blog/img/qemu-legacy.png)

图中vm-exit代表处理器进入host模式，执行kvm和Qemu的逻辑。vm-entry代表处理器进入Guest模式，执行整个Guest系统的逻辑。如图所示，Qemu通过三个文件描述符同kvm.ko交互，然后kvm.ko通过vmcs这个数据结构同处理器交互，最终达到控制Guest系统的效果。其中fd_kvm主要用于Qemu同KVM本身的交互，比如获取KVM的版本号，创建地址空间、vcpu等。fd_vcpu主要用于控制处理器的模式切换，设置进入Guest mode前的处理器状态等等(内存寻址模式，段寄存器、控制寄存器、指令指针等)，同时Qemu需要通过fd_vcpu来mmap一块KVM的数据结构区域。fd_vm主要用于Qemu控制Guest的地址空间，向Guest注入虚拟中断等。

**Virtio**

VirtIO为Guest和Qemu提供了高速的IO通道。Guest的磁盘和网络都是通过VirtIO来实现数据传输的。由于Guest的地址空间mmap到Qemu的进程空间中，VirtIO以共享内存的数据传输方式以及半虚拟化(para-virtualized)接口为Guest提供了高效的硬盘以及网络IO性能。其中，KVM为VirtIO设备与Guest的VirtIO驱动提供消息通知机制，如下图所示：

![](/kvm_blog/img/virtio.png)

如图所示，Guest VirtIO驱动通过访问port空间向Qemu的VirtIO设备发送IO发起消息。而设备通过读写irqfd或者IOCTL fd_vm通知Guest驱动IO完成情况。irqfd和ioeventfd是KVM为用户程序基于内核eventfd机制提供的通知机制，以实现异步的IO处理(这样发起IO请求的vcpu将不会阻塞)。之所以使用PIO而不是MMIO，是因为KVM处理PIO的速度快于MMIO。

**Vhost**

从图1中可以看到，Guest的IO请求需要经过Qemu处理后通过系统调用才会转换成Host的IO请求发送给Host的驱动。虽然共享内存以及半虚拟化接口的通信协议减轻了IO虚拟化的开销，但是Qemu与内核之间的系统模式切换带来的开销是避免不了的。
目前Linux内核社区中的vhost就是将用户态的Virt-IO网络设备放在了内核中，避免系统模式切换以及简化算法逻辑最终达到IO减少延迟以及增大吞吐量的目的。如下图所示：

![](/kvm_blog/img/vhost.png)

目前KVM的磁盘虚拟化还是在用户层通过Qemu模拟设备。我们可以通过vhost框架将磁盘的设备模拟放到内核中达到优化的效果。


# 2. 安装 virtio 驱动 #
virtio 已经是一个比较稳定成熟的技术了，宿主机中比较新的KVM都支持它，Linux2.6.34及以上的Linux内核版本都是支持 virtio的。由于 virtio 的后端处理程序是在位于用户空间的QEMU中实现的，所以，在宿主机中只需要比较新的内核即可，不需要特别地编译与 virtio 相关的驱动。

## 2.1 Linux 中的 virtio 驱动 ##

以RHEL 6.3 中的内核配置文件为例，其中与 virtio 相关的配置有如下几项

	CONFIG_VIRTIO=m
	CONFIG_VIRTIO_RING=m
	CONFIG_VIRTIO_PCI=m
	CONFIG_VIRTIO_BALLOON=m
	CONFIG_VIRTIO_BLK=m
	CONFIG_SCSI_VIRTIO=m
	CONFIG_VIRTIO_NET=m
	CONFIG_VIRTIO_CONSOLE=m
	CONFIG_HW_RANDOM_VIRTIO=m
	CONFIG_NET_9P_VIRTIO=m
	
	find /lib/modules/2.6.32/ -name "virtio*.ko"

## 2.2 Windows 中的 virtio 驱动 ##
virtio驱动下载
http://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers
virtio 驱动 redhat virtio-win.iso
源码下载：https://github.com/hhb584520/kvm-guest-drivers-windows
fedora 的Virtio 驱动：http://alt.fedoraproject.org/pub/alt/virtio-win/latest/images/bin/

virtio 驱动安装

	# qemu-system-x86_64 win7.img -smp 2 -m 2048 -cdrom /usr/share/virtio-win.iso -vnc :0 -usbdevice tablet

安装相关的驱动后，用下面的命令启动虚拟机

	# qemu-system-x86_64 win7.img -smp 2 -m 2048 -cdrom /usr/share/virtio-win.iso -vnc :0 -usbdevice tablet -net nic,model=virtio -net tap -balloon virtio -device virtio-serial-pci

右键找到对应的设备更新驱动即可。对于安装 virtio 驱动程序，其过程和之前的策略略微有些不同
使用一个非启动盘，请其指定为使用 virtio 驱动，像前面那样安装驱动，然后重启系统将启动硬盘的镜像文件也设置为 virtio 方式即可使用virtio 驱动启动客户机系统。

	qemu-img create -f qcow2 fake.qcow2 10M
	qemu-system-x86_64 win7.img -drive file=fake.qcow2,if=virtio -smp 2 -m 2048 -cdrom /usr/share/virtio-win/virtio-win.iso -vnc :0 -usbdevice tablet

安装完驱动后，去掉非启动盘

	qemu-system-x86_64 -drive file=win7.img,if=virtio -smp 2 -m 2048  -vnc :0 -usbdevice tablet

全部安装好后，可以用下面的命令启动虚拟机

	qemu-system-x86_64 -drive file=win7.img,if=virtio -smp 2 -m 2048 -net nic,model=virtio -net tap -balloon virtio-device virtio-serial-pci  -vnc :0 -usbdevice tablet

# 3. 使用virtio_balloon #

## 3.1 Ballooning简介 ##

通常来说，要改变客户机占用的宿主机内存，是要先关闭客户机，修改启动时的内存配置，然后重启客户机才能实现。而内存的ballooning（气球）技术可以在客户机运行时动态地调整它所占用的宿主机内存资源，而不需要关闭客户机。
Ballooning技术形象地在客户机占用的内存中引入气球（Balloon）的概念，气球中的内存是可以供宿主机使用的（但不能被客户机访问或使用），所以，当宿主机内存使用紧张，空余内存不多时，可以请求客户机回收利用已分配给客户机的部分内存，客户机就会释放其空闲的内存，此时若客户机空闲内存不足，可能还会回收部分使用中的内存，可能会换出部分内存到客户机的交换分区（swap）中，从而使得内存气球充气膨胀，从而让宿主机回收气球中的内存可用于其他进程（或其他客户机）。反之，当客户机中内存不足时，也可以让客户机的内存气球压缩，释放出内存气球中的部分内存，让客户机使用更多的内存。
很多现代的虚拟机，如KVM、Xen、VMware等，都对Ballooning技术提供支持。关于内存Balloon的概念，其示意图如图5-9所示。

![](/kvm_blog/img/linux-ballooning.jpg)
 
linux ballooning
linux ballooning
图5-9 内存Balloon的概念

## 3.2 KVM中Ballooning的原理及其优劣势 ##

KVM中Ballooning的工作过程主要如下几个步骤：

1) Hypervisor（即KVM）发送请求到客户机操作系统让其归还一定数量的内存给hypervisor。

2) 客户机操作系统中的virtio_balloon驱动接收到hypervisor的请求。

3) virtio_balloon驱动使客户机的内存气球膨胀，气球中的内存就不能被客户机访问。如果此时客户机中内存剩余量不多（如某应用程序绑定/申请了大量的内存），并不能让内存气球膨胀到足够大以满足hypervisor的请求，那么virtio_balloon驱动也会让尽可能多地提供内存内存使气球膨胀，尽量去满足hypervisor的请求中的内存数量（即使不一定能完全满足）。

4) 客户机操作系统归还气球中的内存给hypervisor。

5) hypervisor可以将从气球中得来的内存分配到任何需要的地方。

6) 如果从气球中得到来内存没有处于使用中，hypervisor也可以将内存返还到客户机中，这个过程为：

- hypervisor发请求到客户机的virtio_balloon驱动；
- 这个请求让客户机操作系统压缩内存气球；
- 在气球中的内存被释放出来，重新让客户机可以访问和使用。

Ballooning在节约内存和灵活分配内存方面有明显的优势，其好处有如下三点。

- 第一，因为能够控制和监控ballooning，所以ballooning能够潜在地节约大量的内存。它不同于内存页共享技术（KSM是内核自发完成的、不可控），客户机系统的内存只有在通过命令行调整balloon时才会随之改变，所以能够监控系统内存并验证ballooning引起的变化。
- 第二，Ballooning对内存的调节很灵活，既可以精细的请求少量内存，又可以粗犷的请求大量的内存。
- 第三，hypervisor使用ballooning让客户机归还部分内存，从而可以缓解其内存压力。而且从气球中回收的内存也不要求一定要被分配给另外某个进程（或另外的客户机）。

从另一方面来说，KVM中ballooning的使用不方便、不完善的地方也是存在的，其缺点也有如下几个。

- Ballooning需要客户机操作系统加载virtio_balloon驱动，然而并非每个客户机系统都有该驱动（如windows需要自己安装该驱动）。
- 如果有大量内存从客户机系统中回收，Ballooning可能会降低客户机操作系统运行的性能。一方面，内存的减少，可能会让客户机中作为磁盘数据缓存的内存被放到气球中，从而客户机中的磁盘I/O访问会增加；另一方面，如果处理机制不够好，也可能让客户机中正在运行的进程由于内存不足而执行失败。
- 目前没有比较方便的、自动化的机制来管理ballooning，一般都是采用在QEMU monitor中执行balloon命令来实现ballooning的。没有对客户机的有效监控，没有自动化的ballooning机制，这可能会让生产环境中实现大规模自动化部署并不很方便。
- 内存的动态增加或减少，可能会使内存被过度碎片化，从而降低内存使用时的性能。另外，内存的变化会影响到客户机内核对内存使用的优化，比如：内核起初根据目前状态对内存的分配采取了某个策略，而突然由于balloon的效果让可用内存减少了很多，这时起初的内存策略可能就不是太优化的了。

## 3.3 KVM中Ballooning使用示例 ##

KVM中的Ballooning是通过宿主机和客户机协同来实现的，在宿主机中应该使用2.6.27及以上版本的Linux内核（包括KVM模块），使用较新的qemu-kvm（如0.13版本以上），在客户机中也使用2.6.27及以上内核且将“CONFIG_VIRTIO_BALLOON”配置为模块或编译到内核。在很多Linux发行版中都已经配置有“CONFIG_VIRTIO_BALLOON=m”，所以用较新的Linux作为客户机系统，一般不需要额外配置virtio_balloon驱动，使用默认内核配置即可。

在QEMU命令行中可用“-balloon virtio”参数来分配Balloon设备给客户机让其调用virtio_balloon驱动来工作，而默认值为没有分配Balloon设备（与“-balloon none”效果相同）。
-balloon virtio[,addr=addr]  #使用VirtIO balloon设备，addr可配置客户机中该设备的PCI地址。
在QEMU monitor中，提供了两个命令查看和设置客户机内存的大小。
(qemu) info balloon   #查看客户机内存占用量（Balloon信息）
(qemu) balloon num   #设置客户机内存占用量为numMB

KVM中使用ballooning的操作步骤如下：

（1）QEMU启动客户机时分配balloon设备，命令行如下所示。也可以使用较新的“-device”的统一参数来分配balloon设备，如“-device virtio-balloon-pci,id=balloon0,bus=pci.0,addr=0×4”。
[root@jay-linux kvm_demo]# qemu-system-x86_64 rhel6u3.img -smp 2 -m 2048 -balloon virtio

（2）在启动好的客户机中查看balloon设备及内存使用情况，命令行如下：

	[root@kvm-guest ~]# lspci
	00:00.0 Host bridge: Intel Corporation 440FX – 82441FX PMC [Natoma] (rev 02)
	00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
	00:01.1 IDE interface: Intel Corporation 82371SB PIIX3 IDE [Natoma/Triton II]
	00:01.3 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 03)
	00:02.0 VGA compatible controller: Cirrus Logic GD 5446
	00:03.0 Ethernet controller: Realtek Semiconductor Co., Ltd. RTL-8139/8139C/8139C+ (rev 20)
	00:04.0 Unclassified device [00ff]: Red Hat, Inc Virtio memory balloon
	[root@kvm-guest ~]# grep VIRTIO_BALLOON \ /boot/config-2.6.32-279.el6.x86_64
	CONFIG_VIRTIO_BALLOON=m
	[root@kvm-guest ~]# lsmod | grep virtio
	virtio_balloon          4856  0
	virtio_pci              7113  0
	virtio_ring             7729  2 virtio_balloon,virtio_pci
	virtio                  4890  2 virtio_balloon,virtio_pci
	[root@kvm-guest ~]# lspci -s 00:04.0 -v
	00:04.0 Unclassified device [00ff]: Red Hat, Inc Virtio memory balloon
	Subsystem: Red Hat, Inc Device 0005
	Physical Slot: 4
	Flags: fast devsel, IRQ 10
	I/O ports at c100 [size=32]
	Kernel driver in use: virtio-pci
	Kernel modules: virtio_pci
	[root@kvm-guest ~]# free -m
	total       used       free     shared    buffers     cached
	Mem:          1877        166       1711          0         21         59
	-/+ buffers/cache:         85       1792
	Swap:          508          0          508

根据上面输出可知，客户机中virtio_balloon模块已经加载，有一个叫做“Red Hat, Inc Virtio memory balloon”的PCI设备，它使用了virtio_pci驱动。如果是Windows客户机，则可以在“设备管理器”看到使用VirtIO Balloon设备。

（3）在QEMU monitor中查看和改变客户机占用的内存，命令如下：

	(qemu) info balloon
	balloon: actual=2048
	(qemu) balloon 512
	(qemu) info balloon
	balloon: actual=512
如果没有使用Balloon设备，则monitor中用“info balloon”命令查看会得到“Device ‘balloon’ has not been activated”的警告提示。而“balloon 512”命令将客户机内存设置为512MB。

（4）设置了客户机内存为512 MB后，再到客户机中检查，如下所示。

	[root@kvm-guest ~]# free -m
	total       used       free     shared    buffers     cached
	Mem:           341        166        175          0         21         59
	-/+ buffers/cache:         85        256
	Swap:         508          0          508

如果是Windows客户机（如Win7），当balloon使其可用内存从2GB降低到512MB时，在其“任务管理器”中看到的内存总数依然是2GB，但是看到它的内存已使用量会增大1536MB（如从其原来使用量350MB，变为1886MB），这里占用的1536MB正是Balloon设备占用的，Windows客户机系统其他程序已不能使用这1636 MB内存，这时宿主机系统就可以再次分配这里的1536MB内存用于其他用途。
另外，值得注意的是，当通过“balloon”命令让客户机内存增加时，其最大值不能超过QEMU命令行启动时设置的内存，例如：命令行中内存设置为2048MB，如果在Monitor中执行“balloon 4096”则设置的4096MB内存不会生效，其值将会被设置为启动命令行中的最大值（即2048MB）。

## 3.4 通过Ballooning过载使用内存 ##

在4.3.4节“内存过载使用”中提到，内存过载使用主要有三种方式：swapping、ballooning和page sharing。在多个客户机运行时动态地调整其内存容量，ballooning是一种让内存过载使用的非常有效的机制。使用ballooning可以根据宿主机中对内存的需求，通过“balloon”命令调整客户机内存占用量，从而可以实现内存的过载使用。

在实际环境中，客户机系统的资源的平均使用率一般并不是很高的，通常是一段时间负载较重，一段时间负载较轻。可以在一个物理宿主机上启动多个客户机，通过ballooning的支持，在某些客户机负载较轻时减少其内存使用，用于分配给此时负载较重的客户机。例如：在一个物理内存在8GB的宿主机上，可以在一开始就分别启动6个内存为2GB的客户机（A、B、C、D、E、F这6个），根据平时对各个客户机里资源使用情况的统计可知，当前一段时间内，A、B、C的负载很轻，就可以通过ballooning降低其内存为512 MB，而D、E、F的内存保持2 GB不变。其内存分配的简单计算为：
512MB × 3  +  2GB × 3  +  512MB（用于宿主机中其他进程） =  8GB
而在其他某些时间段，A、B、C等客户机负载较大时，也可以增加它们的内存量（同时减少D、E、F的内存量）。这样就在8GB物理内存的上运行了看似需要大于12GB内存才能运行的6个2GB内存的客户机，从而较好地实现了内存的过载使用。

如果客户机中有virtio_balloon驱动，则使用ballooning来实现内存过载使用是非常方便的。而前面提到“在QEMU monitor中用balloon命令改变内存操作不方便”的问题，如果使用第6章将会介绍的libvirt工具来使用KVM，则对ballooning的操作会比较方便，在其“virsh”管理程序中就有“setmem”这个命令来动态更改客户机的可用内存容量，该方式的完整命令为“virsh setmem <domain-id or domain-name> <Amount of memory in KB>”。


# 4. 使用virtio_net #

## 4.1 配置和使用virtio_net ##

在选择KVM中的网络设备时，一般来说优先选择半虚拟化的网络设备而不是纯软件模拟的设备，使用virtio_net半虚拟化驱动，可以提高网络吞吐量（thoughput）和降低网络延迟（latency），从而让客户机中网络达到几乎和原生网卡差不多的性能。
virtio_net的使用，需要两部分的支持，在宿主机中的QEMU工具的支持和客户机中virtio_net驱动的支持。较新的qemu-kvm都对virtio网卡设备的支持，且较新的流行Linux发行版中都已经将virtio_net作为模块编译到系统之中了，所以使用起来还是比较方便的。
可以通过如下几个步骤来使用virtio_net。

- 检查QEMU是否支持virtio类型的网卡

	[root@jay-linux kvm_demo]# qemu-system-x86_64 -net nic,model=?
	qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
从输出信息中支持网卡类型可知，当前qemu-kvm支持virtio网卡模型。
- 启动客户机时，指定分配virtio网卡设备。

	[root@jay-linux kvm_demo]# qemu-system-x86_64 rhel6u3.img -smp 2 -m 1024 -net nic,model=virtio,macaddr=00:16:3e:22:22:22 -net tap
	VNC server running on `::1:5900′

- 在客户机中查看virtio网卡的使用情况。

	[root@kvm-guest ~]# grep VIRTIO_ /boot/config-2.6.32-279.el6.x86_64
	CONFIG_VIRTIO_BLK=m
	CONFIG_VIRTIO_NET=m
	CONFIG_VIRTIO_CONSOLE=m
	CONFIG_VIRTIO_RING=m
	CONFIG_VIRTIO_PCI=m
	CONFIG_VIRTIO_BALLOON=m
	[root@kvm-guest ~]# lspci
	00:00.0 Host bridge: Intel Corporation 440FX – 82441FX PMC [Natoma] (rev 02)
	00:01.0 ISA bridge: Intel Corporation 82371SB PIIX3 ISA [Natoma/Triton II]
	00:01.1 IDE interface: Intel Corporation 82371SB PIIX3 IDE [Natoma/Triton II]
	00:01.3 Bridge: Intel Corporation 82371AB/EB/MB PIIX4 ACPI (rev 03)
	00:02.0 VGA compatible controller: Cirrus Logic GD 5446
	00:03.0 Ethernet controller: Red Hat, Inc Virtio network device
	[root@kvm-guest ~]# lspci -vv -s 00:03.0
	00:03.0 Ethernet controller: Red Hat, Inc Virtio network device
	Subsystem: Red Hat, Inc Device 0001
	Physical Slot: 3
	Control: I/O+ Mem+ BusMaster- SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Interrupt: pin A routed to IRQ 11
	Region 0: I/O ports at c000 [size=32]
	Region 1: Memory at febf1000 (32-bit, non-prefetchable) [size=4K]
	Expansion ROM at febe0000 [disabled] [size=64K]
	Capabilities: [40] MSI-X: Enable+ Count=3 Masked-
	Vector table: BAR=1 offset=00000000
	PBA: BAR=1 offset=00000800
	Kernel driver in use: virtio-pci
	Kernel modules: virtio_pci
	[root@kvm-guest ~]# lsmod | grep virtio
	virtio_net             16760  0
	virtio_pci              7113  0
	virtio_ring             7729  2 virtio_net,virtio_pci
	virtio                  4890  2 virtio_net,virtio_pci
	[root@kvm-guest ~]# ethtool -i eth1
	driver: virtio_net
	version:
	firmware-version:
	bus-info: virtio0
	[root@kvm-guest ~]# ifconfig eth1
	eth1      Link encap:Ethernet  HWaddr 00:16:3E:22:22:22
	inet addr:192.168.156.200  Bcast:192.168.255.255  Mask:255.255.0.0
	inet6 addr: fe80::216:3eff:fe22:2222/64 Scope:Link
	UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
	RX packets:500 errors:0 dropped:0 overruns:0 frame:0
	TX packets:103 errors:0 dropped:0 overruns:0 carrier:0
	collisions:0 txqueuelen:1000
	RX bytes:65854 (64.3 KiB)  TX bytes:19057 (18.6 KiB)
	[root@kvm-guest ~]# ping 192.168.199.98 -c 1
	PING 192.168.199.98 (192.168.199.98) 56(84) bytes of data.
	64 bytes from 192.168.199.98: icmp_seq=1 ttl=64 time=0.313 ms
	 
	— 192.168.199.98 ping statistics —
	1 packets transmitted, 1 received, 0% packet loss, time 0ms
	rtt min/avg/max/mdev = 0.313/0.313/0.313/0.000 ms

根据上面输出信息可知，网络接口eth1使用了virtio_net驱动，且当前网络连接正常工作。如果启动Windows客户机使用virtio类型的网卡，则在Windows客户机的“设备管理器”中看到一个名为“Red Hat VirtIO Ethernet Adapter”的设备即是客户机中的网卡。

## 4.2 宿主机中TSO和GSO的设置 ##

据Redhat的文档[3]介绍，如果你在使用半虚拟化网络驱动（即virtio_net）时依然得到较低的性能，可以检查宿主机系统中对GSO和TSO[4]特性的设置。关闭GSO和TSO可以使半虚拟化网络驱动的性能得到更加优化。如下的命令可以检查宿主机中GSO和TSO的设置，其中eth0是建立bridge供客户机使用的网络接口。

	[root@jay-linux ~]# brctl show
	bridge name     bridge id               STP enabled     interfaces
	br0             8000.001320fb4fa8       yes             eth0
	tap0
	[root@jay-linux ~]# ethtool -k eth0
	Offload parameters for eth0:
	rx-checksumming: on
	tx-checksumming: on
	scatter-gather: on
	tcp-segmentation-offload: on           #这个就是TSO的状态
	udp-fragmentation-offload: off
	generic-segmentation-offload: on      #这是GSO的状态
	generic-receive-offload: on
	large-receive-offload: off
	通过如下命令可以关闭其GSO和TSO功能。
	[root@jay-linux ~]# ethtool -K eth0 gso off
	[root@jay-linux ~]# ethtool -K eth0 tso off
	[root@jay-linux ~]# ethtool -k eth0
	Offload parameters for eth0:
	rx-checksumming: on
	tx-checksumming: on
	scatter-gather: on
	tcp-segmentation-offload: off
	udp-fragmentation-offload: off
	generic-segmentation-offload: off
	generic-receive-offload: on
	large-receive-offload: off

## 4.3 用vhost_net后端驱动 ##

前面提到virtio在宿主机中的后端处理程序（backend）一般是由用户空间的QEMU提供的，然而如果对于网络IO请求的后端处理能够在在内核空间来完成，则效率会更高，会提高网络吞吐量和减少网络延迟。在比较新的内核中有一个叫做“vhost-net”的驱动模块，它是作为一个内核级别的后端处理程序，将virtio-net的后端处理任务放到内核空间中执行，从而提高效率。在第4章介绍“使用网桥模式”的网络配置时，有几个选项和virtio相关的，这里也介绍一下。

-net tap,[,vnet_hdr=on|off][,vhost=on|off][,vhostfd=h][,vhostforce=on|off]
vnet_hdr =on|off

设置是否打开TAP设备的“IFF_VNET_HDR”标识。“vnet_hdr=off”表示关闭这个标识；“vnet_hdr=on”则强制开启这个标识，如果没有这个标识的支持，则会触发错误。IFF_VNET_HDR是tun/tap的一个标识，打开它则允许发送或接受大数据包时仅仅做部分的校验和检查。打开这个标识，可以提高virtio_net驱动的吞吐量。

vhost=on|off

设置是否开启vhost-net这个内核空间的后端处理驱动，它只对使用MIS-X[5]中断方式的virtio客户机有效。

vhostforce=on|off

设置是否强制使用vhost作为非MSI-X中断方式的Virtio客户机的后端处理程序。

vhostfs=h

设置为去连接一个已经打开的vhost网络设备。
 
用如下的命令行启动一个客户机，就在客户机中使用virtio-net作为前端驱动程序，而后端处理程序则使用vhost-net（当然需要当前宿主机内核支持vhost-net模块）。

	[root@jay-linux kvm_demo]# qemu-system-x86_64 rhel6u3.img -smp 2 -m 1024 -net nic,model=virtio,macaddr=00:16:3e:22:22:22 -net tap,vnet_hdr=on,vhost=on
	VNC server running on `::1:5900′

启动后，检查客户机网络，应该是可以正常连接的。
而在宿主机中，可以查看vhost-net的使用情况，如下。

	[root@jay-linux kvm_demo]# grep VHOST /boot/config-3.5.0
	CONFIG_VHOST_NET=m
	[root@jay-linux kvm_demo]# lsmod | grep vhost
	vhost_net              17161  1
	tun                    13220  3 vhost_net
	[root@jay-linux kvm_demo]# rmmod vhost-net
	ERROR: Module vhost_net is in use

可见，宿主机中内核将vhost-net编译为module，此时vhost-net模块处于使用中状态（试图删除它时即报告了一个“在使用中”的错误）。一般来说，使用vhost-net作为后端处理驱动可以提高网络的性能。不过，对于一些网络负载类型使用vhost-net作为后端，却可能使其性能不升反降。特别是从宿主机到其中的客户机之间的UDP流量，如果客户机处理接受数据的速度比宿主机发送的速度要慢，这时就容易出现性能下降。在这种情况下，使用vhost-net将会是UDP socket的接受缓冲区更快地溢出，从而导致更多的数据包丢失。故这种情况下，不使用vhost-net，让传输速度稍微慢一点，反而会提高整体的性能。使用qemu-kvm命令行，加上“vhost=off”（或没有vhost选项）就会不使用vhost-net，而在使用libvirt时，需要对客户机的配置的XML文件中的网络配置部分进行如下的配置，指定后端驱动的名称为“qemu”（而不是“vhost”）。

	<interface type=”network”>
	…
	<model type=”virtio”/>
	<driver name=”qemu”/>
	…
	</interface>

# 5. 使用virtio_blk #

virtio_blk驱动使用Virtio API为客户机的提供了一个高效访问块设备I/O的方法。在QEMU/KVM对块设备使用virtio，需要两方面的配置：客户机中的前端驱动模块virtio_blk和宿主机中的QEMU提供后端处理程序。目前比较流行的Linux发行版一般都将virtio_blk编译为内核模块了，可以作为客户机直接使用virtio_blk，而windows中virtio驱动的安装方法已在5.1.2节中做了介绍。并且较新的qemu-kvm都是支持virtio block设备的后端处理程序的。启动一个使用virtio_blk作为磁盘驱动的客户机，其qemu-kvm命令行如下。

	[root@jay-linux]# qemu-system-x86_64 -smp 2 -m 1024 -net nic -net tap –drive file=rhel6u3.img,if=virtio
	VNC server running on `::1:5900

在客户机中，查看virtio_blk生效的情况如下所示。

	[root@kvm-guest ~]# grep VIRTIO_BLK \ /boot/config-2.6.32-279.el6.x86_64
	CONFIG_VIRTIO_BLK=m
	[root@kvm-guest ~]# lsmod | grep virtio
	virtio_blk              7292  3
	virtio_pci              7113  0
	virtio_ring             7729  2 virtio_blk,virtio_pci
	virtio                  4890  2 virtio_blk,virtio_pci
	[root@kvm-guest ~]# lspci | grep -i block
	00:04.0 SCSI storage controller: Red Hat, Inc Virtio block device
	[root@kvm-guest ~]# lspci -vv -s 00:04.0
	00:04.0 SCSI storage controller: Red Hat, Inc Virtio block device
	Subsystem: Red Hat, Inc Device 0002
	Physical Slot: 4
	Control: I/O+ Mem+ BusMaster- SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Interrupt: pin A routed to IRQ 11
	Region 0: I/O ports at c100 [size=64]
	Region 1: Memory at febf2000 (32-bit, non-prefetchable) [size=4K]
	Capabilities: [40] MSI-X: Enable+ Count=2 Masked-
	Vector table: BAR=1 offset=00000000
	PBA: BAR=1 offset=00000800
	Kernel driver in use: virtio-pci
	Kernel modules: virtio_pci
	 
	[root@kvm-guest ~]# fdisk -l
	 
	Disk /dev/vda: 8589 MB, 8589934592 bytes
	16 heads, 63 sectors/track, 16644 cylinders
	Units = cylinders of 1008 * 512 = 516096 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk identifier: 0x000726b0
	 
	Device Boot      Start         End      Blocks   Id  System
	/dev/vda1   *           3       14826     7471104   83  Linux
	/dev/vda2           14826       16645      916480   82  Linux swap / Solaris

可知客户机中已经加载virtio_blk等驱动，SCSI磁盘设备是使用virtio_blk驱动（上面查询结果中显示为virtio_pci，因为它是作为任意virtio的PCI设备的一个基础、必备的驱动）。使用virtio_blk驱动的磁盘显示为“/dev/vda”，这不同于IDE硬盘的“/dev/hda”或者SATA硬盘的“/dev/sda”这样的显示标识。
而“/dev/vd*”这样的磁盘设备名称可能会导致从前分配在磁盘上的swap分区失效，因为有些客户机系统中记录文件系统信息的“/etc/fstab”文件中有类似如下的对swap分区的写法。

	/dev/sda2  swap swap defaults 0 0
	或  /dev/hda2  swap swap defaults 0 0

原因就是换为“/dev/vda2”这样的磁盘分区名称未被正确识别，解决这个问题的方法就很简单了，只需要修改它为如下的形式并保存“/etc/fstab”文件，然后重启客户机系统即可。

	/dev/vda2  swap swap defaults 0 0

如果启动的是已安装virtio驱动的Windows客户机，则在客户机的“设备管理器”中的“存储控制器”中看到的是正在使用“Red Hat VirtIO SCSI Controller”设备作为磁盘。

# 6. kvm_clock #

由于在虚拟机中的中断并非真正的中断，而是通过宿主机向客户机注入的虚拟中断，因此中断并不总是能同时且立即传递给一个客户机的所有虚拟CPU（vCPU）。在需要向客户机注入中断时，宿主机的物理 CPU 可能正在执行其他客户机的 vCPU或在运行其他一些非 QEMU 进程，这就是说中断需要的时间精准性有可能得不到保障。

其中QEMU/KVM提供了一个半虚拟化的时钟 kvm_clock。但是它需要硬件支持 Constant TSC(它的计数的频率，即使当前CPU核心改变频率，也能保持恒定不变)。可以通过如下命令来查看宿主机是否支持 Constant TSC:

     grep constant_tsc /proc/cpuinfo

一般在较新的 Linux 发行版的内核中都已经将 kvm_clock相关的支持编译进去了，可以查看如下的内核配置选项：
     
	grep PARAVIRT_GUEST /boot/config-2.6.32-279.e16.c86_64

而在用QEMU命令启动客户机时，已经会默认让其使用 kvm_clock 作为时钟来源。用最普通的命令启动一个 Linux 客户机，然后查看客户机与时钟相关的信息如下，可知使用了kvm_clock和硬件的TSC支持。

     dmesg | grep -i clock
    
另外，Intel 的一些较新的硬件还向时钟提供了更高级的硬件支持，即 TSC Deadline Timer，TSC deadline 模式不是使用CPU外部总线的频率去定时减少计数器的值，而是软件设置了最后期限的阈值，当CPU的时间戳计数器的值大于或等于这个“deadline"时，本地的高级可编程中断控制器（LAPIC）就产生一个时钟中断请求。正是由于这个特点，它可以 提供更精准的时间，也可以更容易避免或处理竞态条件 。
    
KVM模块对于 TSC Deadline Timer的支持开始于 Linux 3.6 版本，QEMU对于TSC Deadline Timer的支持开始于 qemu-kvm 0.12 版本。而且在启动客户机时，在 qemu-kvm 命令行使用“-cpu host" 参数才能将这个特性传递给客户机，使其可以使用 TSC Deadline Timer。