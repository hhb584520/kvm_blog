## 内存过载使用 ##

内存交换、气球（balloon）、页共享（KSM）

# 1. 内存交换
省略，这不属于虚拟化的内容，属于OS本身就有的

# 2. 页共享(KSM)
## 2.1 简介 ##
作为一个系统管理程序（hypervisor），Linux® 有几个创新，2.6.32 内核中一个有趣的变化是 KSM(Kernel Samepage Merging)  允许这个系统管理程序通过合并内存页面来增加并发虚拟机的数量。本文探索 KSM 背后的理念（比如存储去耦合）、KSM 的实现、以及如何管理 KSM。虚拟化技术从上世纪 60 年代开始出现，经由 IBM® System/360® 大型机得以流行。50 年过后，虚拟化技术取得了跨越式发展，使得多个操作系统和应用程序共享一个服务器成为可能。这一特殊用途（称为服务器虚拟化）正在演变为数据中心，因为单个物理机能够用于托管 10 个（一般情况）或更多虚拟机（VM）。这种虚拟化使基础设施更动态、更省电、（因而也）更经济。页面都是相同的。假如操作系统和应用程序代码以及常量数据在 VMs 之间相同，那么这个特点就很有用。当页面惟一时，它们可以被合并，从而释放内存，供其他应用程序使用。 

## 2.2 特性命名 ##
本文描述的特性非常新；因此，其名称经历了一些变化。您将发现这个 Linux 内核特性称为 Kernel Shared Memory 或 Kernel Samepage Merging。
您很快就会发现，尽管 Linux 中的内存共享在虚拟环境中有优势（KSM 最初设计用于基于内核的虚拟机），但它在非虚拟环境中仍然有用。事实上，KSM 甚至在嵌入式 Linux 系统中也有用处，表明了这种方法的灵活性。下面，我们将探索这种 Linux 内存共享方法，以及如何使用该方法提高服务器的内存密度，从而增加其托管其他应用程序或 VMs 的能力。
 
 
## 2.3 KSM 操作 ##

KSM 作为内核中的守护进程（称为 ksmd）存在，它定期执行页面扫描，识别副本页面并合并副本，释放这些页面以供它用。KSM 执行上述操作的过程对用户透明。例如，副本页面被合并（然后被标记为只读），但是，如果这个页面的其中一个用户由于某种原因更改该页面，该用户将（以 CoW 方式）收到自己的副本。可以在内核源代码 ./mm/ksm.c 中找到 KSM 内核模块的完整实现。KSM 依赖高级应用程序来提供指导，根据该指导确定合并的候选内存区域。尽管 KSM 可以只扫描系统中的匿名页面，但这将浪费 CPU 和内存资源（考虑到管理页面合并进程所需的空间）。因此，应用程序可以注册可能包含副本页面的虚拟区域。KSM 应用程序编程接口（API）通过 madvise 系统调用（见清单 1）和一个新的建议参数（advice parameter）MADV_MERGEABLE（表明已定义的区域可以合并）来实现。可以通过 MADV_UNMERGEABLE 参数（立即从一个区域取消合并任何已合并页面）从可合并状态删除一个区域。注意，通过 madvise 来删除一个页面区域可能会导致一个 EAGAIN 错误，因为该操作可能会在取消合并过程中耗尽内存，从而可能会导致更大的麻烦（内存不足情况）。
清单 1. madvise 系统调用

	#include <sys/mman.h>
	int madvise( void *start, size_t length, int advice );
     一旦某个区域被定义为 “可合并”，KSM 将把该区域添加到它的工作内存列表。启用 KSM 时，它将搜索相同的页面，以写保护的 CoW 方式保留一个页面，释放另一个页面以供它用。
     KSM 使用的方法与内存去耦合中使用的方法不同。在传统的去耦合中，对象被散列化，然后使用散列值进行初始相似性检查。当散列值一致时，下一步是进行一个实际对象比较（本例中是一个内存比较），以便正式确定这些对象是否一致。KSM 在它的第一个实现中采用这种方法，但后来开发了一种更直观的方法来简化它。
     在当前的 KSM 中，页面通过两个 “红-黑” 树管理，其中一个 “红-黑” 树是临时的。第一个树称为不稳定树，用于存储还不能理解为稳定的新页面。换句话说，作为合并候选对象的页面（在一段时间内没有变化）存储在这个不稳定树中。不稳定树中的页面不是写保护的。第二个树称为稳定树，存储那些已经发现是稳定的且通过 KSM 合并的页面。为确定一个页面是否是稳定页面，KSM 使用了一个简单的 32 位校验和（checksum）。当一个页面被扫描时，它的校验和被计算且与该页面存储在一起。在一次后续扫描中，如果新计算的校验和不等于此前计算的校验和，则该页面正在更改，因此不是一个合格的合并候选对象。
     使用 KSM 进程处理一个单一的页面时，第一步是检查是否能够在稳定树中发现该页面。搜索稳定树的过程很有趣，因为每个页面都被视为一个非常大的数字（页面的内容）。一个 memcmp（内存比较）操作将在该页面和相关节点的页面上执行。如果 memcmp 返回 0，则页面相同，发现一个匹配值。反之，如果 memcmp 返回 -1，则表示候选页面小于当前节点的页面；如果返回 1，则表示候选页面大于当前节点的页面。尽管比较 4KB 的页面似乎是相当重量级的比较，但是在多数情况下，一旦发现一个差异，memcmp 将提前结束。请参见图 3 查看这个过程的视觉呈现。


     如果候选页面位于稳定树中，则该页面被合并，候选页面被释放。有关代码位于 ksm.c/stable_tree_search()（称为 ksm.c/cmp_and_merge_page()）中。反之，如果没有发现候选页面，则应转到不稳定树（参见 ksm.c/unstable_tree_search()）。
     在不稳定树中搜索时，第一步是重新计算页面上的校验和。如果该值与原始校验和不同，则本次扫描的后续搜索将抛弃这个页面（因为它更改了，不值得跟踪）。如果校验和没有更改，则会搜索不稳定树以寻找候选页面。不稳定树的处理与稳定树的处理有一些不同。第一，如果搜索代码没有在不稳定树中发现页面，则在不稳定树中为该页面添加一个新节点。但是如果在不稳定树中发现了页面，则合并该页面，然后将该节点迁移到稳定树中。
     当扫描完成（通过 ksm.c/ksm_do_scan() 执行）时，稳定树被保存下来，但不稳定树则被删除并在下一次扫描时重新构建。这个过程大大简化了工作，因为不稳定树的组织方式可以根据页面的变化而变化（还记得不稳定树中的页面不是写保护的吗？）。由于稳定树中的所有页面都是写保护的，因此当一个页面试图被写入时将生成一个页面故障，从而允许 CoW 进程为写入程序取消页面合并（请参见 ksm.c/break_cow()）。稳定树中的孤立页面将在稍后被删除（除非该页面的两个或更多用户存在，表明该页面还在被共享）。
     如前所述，KSM 使用 “红-黑” 树来管理页面，以支持快速查询。实际上，Linux 包含了一些 “红-黑” 树作为一个可重用的数据结构，可以广泛使用它们。“红-黑” 树还可以被 Completely Fair Scheduler (CFS) 使用，以便按时间顺序存储任务。您可以在 ./lib/rbtree.c 中找到 “红-黑” 树的这个实现。
 
## 2.4. KSM 配置和监控 ##
KSM 的管理和监控通过 sysfs（位于根 /sys/kernel/mm/ksm）执行。在这个 sysfs 子目录中，您将发现一些文件，有些用于控制，其他的用于监控。第一个文件 run 用于启用和禁用 KSM 的页面合并。默认情况下，KSM 被禁用（0），但可以通过将一个 1 写入这个文件来启用 KSM 守护进程（例如，echo 1 > sys/kernel/mm/ksm/run）。通过写入一个 0，可以从运行状态禁用这个守护进程（但是保留合并页面的当前集合）。另外，通过写入一个 2，可以从运行状态（1）停止 KSM 并请求取消合并所有合并页面。KSM 运行时，可以通过 3 个参数（sysfs 中的文件）来控制它。sleep_millisecs 文件定义执行另一次页面扫描前 ksmd 休眠的毫秒数。max_kernel_pages 文件定义 ksmd 可以使用的最大页面数（默认值是可用内存的 25%，但可以写入一个 0 来指定为无限）。最后，pages_to_scan 文件定义一次给定扫描中可以扫描的页面数。任何用户都可以查看这些文件，但是用户必须拥有根权限才能修改它们。还有 5 个通过 sysfs 导出的可监控文件（均为只读），它们表明 ksmd 的运行情况和效果。full_scans 文件表明已经执行的全区域扫描的次数。剩下的 4 个文件表明 KSM 的页面级统计数据：-

- pages_shared：KSM 正在使用的不可交换的内核页面的数量。 
- pages_sharing：一个内存存储指示。 
- pages_unshared：为合并而重复检查的惟一页面的数量。 
- pages_volatile：频繁改变的页面的数量。 
  
KSM 作者定义：较高的 pages_sharing/pages_shared 比率表明高效的页面共享（反之则表明资源浪费）。

结束语
Linux 并不是使用页面共享来改进内存效率的惟一系统管理程序，但是它的独特之处在于将其实现为一个操作系统特性。VMware 的 ESX 服务器系统管理程序将这个特性命名为 Transparent Page Sharing (TPS)，而 XEN 将其称为 Memory CoW。不管采用哪种名称和实现，这个特性都提供了更好的内存利用率，从而允许操作系统（KVM 的系统管理程序）过量使用内存，支持更多的应用程序或 VM。 您可以在最新的 2.6.32 Linux 内核中发现 KSM — 以及其他很多有趣的特性。
 
转自：http://tech.ddvip.com/2010-05/1273717017153364_2.html
更多阅读：http://www.linux-kvm.com/content/using-ksm-kernel-samepage-merging-kvm
http://www.linux-kvm.org/page/KSM

Pasted from: http://blog.csdn.net/summer_liuwei/article/details/6013255

# 3. 使用virtio_balloon #
## 3.1 Ballooning简介 ##
通常来说，要改变客户机占用的宿主机内存，是要先关闭客户机，修改启动时的内存配置，然后重启客户机才能实现。而内存的ballooning（气球）技术可以在客户机运行时动态地调整它所占用的宿主机内存资源，而不需要关闭客户机。
Ballooning技术形象地在客户机占用的内存中引入气球（Balloon）的概念，气球中的内存是可以供宿主机使用的（但不能被客户机访问或使用），所以，当宿主机内存使用紧张，空余内存不多时，可以请求客户机回收利用已分配给客户机的部分内存，客户机就会释放其空闲的内存，此时若客户机空闲内存不足，可能还会回收部分使用中的内存，可能会换出部分内存到客户机的交换分区（swap）中，从而使得内存气球充气膨胀，从而让宿主机回收气球中的内存可用于其他进程（或其他客户机）。反之，当客户机中内存不足时，也可以让客户机的内存气球压缩，释放出内存气球中的部分内存，让客户机使用更多的内存。
很多现代的虚拟机，如KVM、Xen、VMware等，都对Ballooning技术提供支持。关于内存Balloon的概念，如下图所示。

![](/kvm_blog/files/virt_mem/virt-bolloon.gif)

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