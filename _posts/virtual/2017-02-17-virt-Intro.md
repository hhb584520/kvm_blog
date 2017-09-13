# Intel虚拟化技术 #

## 1. 虚拟化分类

### 1.1 Intel虚拟化技术分类 ##

第一类是处理器相关的，称为VT-x，是实现处理器虚拟化的硬件扩展，这也是硬件虚拟化的基础；
VT-x/VT-i：主要在处理器中实现，允许虚拟机直接执行某些指令，减少VMM负担，以获得更稳定、快速的虚拟机。VT-x指至强处理器的VT技术，VT-i指安腾处理器的VT技术。支持VT的CPU列表

第二类是芯片组相关的，称为VT-d，是从芯片组的层面为虚拟化提供必要支持，通过它，可以实现诸如直接分配物理设备给客户机的功能；
VT-d：VT for Direct I/O，主要在芯片组中实现，允许虚拟机直接访问I/O设备，以减少VMM和CPU的负担。

第三类是输入输出设备相关的，主要目的是通过定义新的输入输出协议，使新一代的输入输出设备可以更好地支持虚拟化环境下的工作，比如Intel网卡自有的VMDq技术和PCI组织定义的单根设备虚拟化协议（SR-IOV）.
VT-c：VT for Connectivity，主要在网卡上实现，包括两个核心技术：VMDq和VMDc。
VMDq：通过网卡上的特定硬件将不同虚拟机的数据包预先分类，然后通过VMM分发给各虚拟机，以此减少由VMM进行数据包分类的CPU开销
VMDc：允许虚拟机直接访问网卡设备。Single Root I/O Virtualization（SR-IOV）是PCI-SIG规范，可以将一个PCIe设备分配给多个虚拟机来直接访问。目前82599万兆控制器和82576千兆控制器支持SR-IOV

### 1.2 根据虚拟方法分类 ###
VMM采用特权级 0，GOS采用的内核采用特权级1。 陷入模拟即可完成虚拟化，但存在以下问题：
特权指令指的是系统中操作和管理关键系统资源的指令，因为它只能在最高特权级上正确运行；敏感指令是虚拟化中的概念，它指的是操作特权资源的指令，它包括修改虚拟机的运行模式或下面物理机的状态；读写敏感指令的寄存器或内存（如时钟或者中断寄存器）；访问存储保护系统、内存系统或是地址重定位系统以及所有的 I/O指令）。
判断一个系统是否可虚拟化，其关键就在该系统对敏感指令的支持上。如果系统上所有的敏感指令都是特权指令，则它是可虚拟化的；否则，如果它不能在所有的敏感指令上触发异常，则不是可虚拟化的，我们称之为“虚拟化漏洞”。
少数敏感指令是非特权指令，如 x86 的 sgdt/sidt 等，非特权指令可以在用户态读取处理器的状态，如 sgdt/sidt 则可在用户态 (Ring3) 将 GDTR 和 IDTR 的值读取到通用寄存器中。
虚拟化漏洞规避有以下几种方法：
修改GOS，使其不产生这样的“漏洞”指令（半虚）
模拟（Bochs），针对每条指令进行翻译并模拟，效率低下（全虚）
动态二进制翻译（Qemu)，将难以虚拟化的指令转化为支持虚拟化的指令，VMM对操作系统的二进制代码进行扫描，一旦发现需要处理的指令，就将其翻译成支持虚拟化的指令块。动态编译--效率一般（全虚）
硬件辅助虚拟化



## 2. 虚拟化方案 ##

### 2.1 Xen 与 KVM 比较 ###

![](/kvm_blog/files/virt_intro/virtualization.png)

Xen是Linux下的一个虚拟化解决方案，但由于被Citrix收购后，变成了和红帽企业版一样了，卖服务收取费用，Redhat从rhel6.0开始已经从内核中把XEN踢出去了，全心投入开发免费的KVM，虽然市场上老用户还在用Xen,但相信kvm会逐步占领大面积的市场，必竟有redhat做为强大支持源。

Xen的实现方法是运行支持Xen功能的kernel，这个kernel是工作在Xen的控制之下，叫做Domain0，使用这个kernel启动机器后，你可以在这个机器上使用qemu软件，虚拟出多个系统。Xen的缺点是如果你需要更新Xen的版本，你需要重新编译整个内核，而且，稍有设置不慎，系统就无法启动。

相比较，KVM就简化的多了。它不需要重新编译内核，也不需要对当前kernel做任何修改，它只是几个可以动态加载的.ko模块。它结构更加精简、代码量更小。所以，出错的可能性更小。并且在某些方面，性能比Xen更胜一筹。

## 2.2 容器虚拟化 ##

![](/kvm_blog/files/virt_intro/docker.png)

### 2.2.1 LXC
LXC是所谓的OS层次的虚拟化技术，与传统的HAL层次的虚拟化技术相比有以下优势：

- 更小的虚拟化开销（LXC的诸多特性基本由内核提供，而内核实现这些特性只是极少的花费。
- 快速部署。利用LXC来隔离特定应用，只需要安装LXC，即可使用LXC相关的命令来创建并启动容器来为应用提供虚拟化环境。传统的虚拟化技术则需要先创建VM，然后安装系统，再部署应用。   

### 2.2.2 Docker
Docker 最初是 dotCloud 公司创始人 Solomon Hykes 在法国期间发起的一个公司内部项目，它是基于 dotCloud 公司多年云服务技术的一次革新，并于 2013 年 3 月以 Apache 2.0 授权协议开源)，主要项目代码在 GitHub 上进行维护。Docker 项目后来还加入了 Linux 基金会，并成立推动开放容器联盟。

Docker 自开源后受到广泛的关注和讨论，至今其 GitHub 项目已经超过 3 万 6 千个星标和一万多个 fork。甚至由于 Docker 项目的火爆，在 2013 年底，dotCloud 公司决定改名为 Docker。Docker 最初是在 Ubuntu 12.04 上开发实现的；Red Hat 则从 RHEL 6.5 开始对 Docker 进行支持；Google 也在其 PaaS 产品中广泛应用 Docker。

Docker 使用 Google 公司推出的 Go 语言 进行开发实现，基于 Linux 内核的 cgroup，namespace，以及 AUFS 类的 Union FS 等技术，对进程进行封装隔离，属于操作系统层面的虚拟化技术。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。最初实现是基于 LXC，从 0.7 以后开始去除 LXC，转而使用自行开发的 libcontainer，从 1.11 开始，则进一步演进为使用 runC 和 containerd。

Docker 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护。使得 Docker 技术比虚拟机技术更为轻便、快捷。

下面的图片比较了 Docker 和传统虚拟化方式的不同之处。传统虚拟机技术是虚拟出一套硬件后，在其上运行一个完整操作系统，在该系统上再运行所需应用进程；而容器内的应用进程直接运行于宿主的内核，容器内没有自己的内核，而且也没有进行硬件虚拟。因此容器要比传统虚拟机更为轻便。


## 2.3 系统虚拟化和容器技术相结合 ##
有多种方式可以将系统虚拟化及容器技术相结合：

**一个容器中运行一个虚拟机**

Docker在部署容器方面十分灵活。其中一个选择（execution driver）是利用KVM镜像。这样就可以在最好的隔离性情况下发挥DevOps所擅长的使用Docker各种方式。但是这也付出了需要在启动容器时启动整个操作系统实例的代价。这也就意味着较长的启动时间以及低效的内存使用，只能通过内核共享内存（KSM）来提升内存利用率。这种方法效果和效率都不理想，但是这是一个好的开始。

**一个虚拟机中运行一个容器**

与之相反的，你一可以在虚拟机中启动一个容器。这里的虚拟机并不是由Docker控制，而是通过现有的虚拟化管理设施来控制。一旦系统实例启动，就可以通过Docker来运行容器而武器其他特殊的设置。同时，由于不同容器运行在不同的虚拟机上，容器之间也能有很好的隔离。而内存的使用率需要通过虚拟层的内存共享来提升。

**一个虚拟机中运行多个容器**

![](/kvm_blog/files/virt_intro/docker-tenant-in-vm.png)


对于多租户的情况，可以用另一种形式在虚拟机中运行Docker。这种情况下，我们假设在不同租户的容器之间需要强隔离，而对于同一用户的不同容器，简单的Linux容器隔离已经足够。这样我们就可以在减少虚拟机个数的情况下保证租户之间的隔离，同时可以利用Docker带来的各种便利。

## 2.4 Openstack, kvm及qemu以及libvirt之间的关系 ##
KVM是最底层的hypervisor，它是用来模拟CPU的运行，它缺少了对network和周边I/O的支持，所以我们是没法直接用它的。QEMU就是一个完整的模拟器，它是基于KVM上面的，它提供了完整的网络和I/O支持. Openstack不会直接控制qemu-kvm，它会用一个叫libvit的库去间接控制qemu， libvirt提供了 跨VM平台的功能，它可以控制除了QEMU的模拟器，包括vmware, virtualbox xen等等。所以为了openstack的跨VM性，所以openstack(Nova/Cinder/Glance)只会用libvirt而不直接用qemu。libvirt还提供了一些高级的功能，例如pool/vol管理。

准确来说，KVM是Linux kernel的一个模块。可以用命令modprobe去加载KVM模块。加载了模块后，才能进一步通过其他工具创建虚拟机。但仅有KVM模块是 远远不够的，因为用户无法直接控制内核模块去作事情,你还必须有一个运行在用户空间的工具才行。这个用户空间的工具，kvm开发者选择了已经成型的开源虚拟化软件 QEMU。说起来QEMU也是一个虚拟化软件。它的特点是可虚拟不同的CPU。比如说在x86的CPU上可虚拟一个Power的CPU，并可利用它编译出可运行在Power上的程序。KVM使用了QEMU的一部分，并稍加改造，就成了可控制KVM的用户空间工具了。所以你会看到，官方提供的KVM下载有两大部分(qemu和kvm)三个文件(KVM模块、QEMU工具以及二者的合集)。也就是说，你可以只升级KVM模块，也可以只升级QEMU工具。这就是KVM和QEMU 的关系。

零基础学习openstack  
http://www.aboutyun.com/thread-10124-1-1.html

## 3. 大公司支持 ##
IBM不仅有着44年丰富的虚拟化经验，在投资开源虚拟化方面也眼光独到。开源KVM能够提供最佳可扩展性与高性能高安全，同时也是最具性价比的开源虚拟化解决方案。2007年，IBM将KVM作为最佳虚拟化开放技术，投入了巨资。此后，IBM不仅联合红帽等厂商成立OVA，帮助构建KVM生态系统，扩展开源虚拟化市场，而且IBM还有60多位程序员专门工作于KVM开源社区。

### 3.1 IBM对KVM的投资与开发 ###

IBM对KVM开发的关键领域主要包括以下几个方面：

一、核心KVM开发。这包括支持内存过量分配的内存管理，充分利用QEMU虚拟机环境子系统的内存。

二、性能与可扩展性。进行SPECvirt基准测试，围绕着云的优化与性能提升。

三、系统管理。包括对libvirt-CIM管理界面，开发libvirt存储系统。

四、安全与可靠性。包括公共标准认证，涉及目前最新的EAL4+。

五、网络与I/O。Single Root I/O Virtualization(SR-IOV)支持，提升物理PCI设备的虚拟化效能。

六、云优化。支持高密度虚拟化，将虚拟机从VMware与EC2迁移到KVM。

七、数据中心网络。包括网络配置自动化，额外安全支持等。

由此看出，IBM主要从三大领域对KVM进行投资，即性能与可扩展性、安全与可靠性以及云优化，让KVM业务为企业业务就绪。

### 3.2 IBM的KVM解决方案 ###

IBM的KVM方案与红帽有着千丝万缕的联系。

首先，IBM x架构突破了在x86架构上进行虚拟的一些限制。随着虚拟化的发展，x86硬件要足够敏捷才能让客户享受到虚拟化的所有益处。

IBM eX5的MAX5内存扩展能让客户部署红帽企业虚拟化，在单台服务器上运行多个虚拟机，达到高比率整合。MAX5也能扩展内存，达到非eX5服务器内存容量的五倍。在传统10G系统，I/O容量也有四倍提升。

IBM首次将RHEV结合x86模型带入行业，交付优化的服务器性能、领先的可扩展性、显著的I/O提升，帮助用户实现高级的资产利用率和工作负载管理。随着红帽RHEV 3.0的发布，这种一体化的解决方案立即可用。

安全是企业用户采用开源虚拟化技术的重要考量因素。结合红帽企业Linux和IBM System x，使得KVM的安全级别达到了EAL4+。红帽企业Linux拥有安全增强功能SELinux，它是与美国国家安全局(NSA)共同开发的项目。当该功能集成于KVM hypervisor后，云供应商能在一台机器上安全地宿主多租户，通过NSA的Mandatory Access Control(强制访问控制)技术实现虚拟子机的隔离。

带有KVM hypervisor的红帽企业Linux 5.6与6.2版本，正在进行通用标准认证EAL4+级别安全的认证，达到了高安全。RHEL 5.6与IBM System x的组合也成为首个实现EAL4+安全级别的认证开源虚拟化解决方案。这样的解决方案能应用于政府、金融及其他对安全要求高的行业中。

### 3.3 KVM 和 Xen 的比较 ###
#### 3.3.1 宏观考虑 ####
**生态链层面**
KVM到2014年Redhat都不支持了。 Xen 只有Suse和Oracle支持

**架构层面**
Xen主要是负责半虚，KVM主要是负责全虚，需要CPU支持VT。主流的虚拟化都还是聚焦在全虚上面。Xen是混合模式，Kvm是宿主机模式。从架构上讲，xen是自定制的hypervisor，对硬件的资源管理和调度，对虚拟机的生命周期管理等，都是从头开始写的。  KVM全称是Kernel-based Virtual Machine, kernel代表的是Linux kernel。KVM是一个特殊的模块，Linux kernel加载此模块后，可以将Linux kernel 变成hypervisor，因为Linux kernel已经可以很好的实现对硬件资源的调度和管理，KVM只是实现了对虚拟机生命周期管理的相关工作。 KVM的初始版本只有4万行代码，相对于xen的几百万行代码显得非常简洁。

**安全**
Xen需要考虑三方面的安全，一是Hypervisor，二是Dom0，三是DomU。 Kvm主要考虑宿主机和虚拟机的安全

**历史**
许多人都是自己构建内核，Xen可以运行在很多服务器上，从低成本的虚拟专用服务器（Virtual Private Server，VPS）供应商，如Linode，到大型公司，如Amazon的EC2，这些公司都加大了这方面的投入，不会轻易转换到其它技术，即使技术上KVM超越了Xen，也不能一下就取代现有的解决方案，更何况KVM在技术上的优势并不明显，有些地方甚至还未超越Xen，因为Xen的历史比KVM更悠久，它也比KVM更成熟，你会发现Xen中的某些功能在KVM还未实现，因此我们看到KVM项目的Todo List很长，KVM的优势也仅限于它进入了Linux内核。从RHEL 5.4开始，RedHat就支持KVM了，从RHEL 6.0开始RedHat就完全抛弃Xen了。

#### 3.3.2 微观层面 ####
**CPU调度**
需要VT的支持，所以KVM无法历旧，这一块有很大市场，CPU调度层面来考虑，明显没有CFS调度算法简单和高效。当有一个vcpu处理IO时，还可以切换给其它VCPU上面。

**IO虚拟化**
这一块本来是XEN做的最好的，因为XEN是做半虚出家的，所以他的前后端做的非常好，但是现在KVM也有VIRTIO，正在迎头赶上。


#### 3.3.3 虚拟化外围 ####
**虚拟机管理**
虚拟机的管理和迁移，RHEV应该会把她做好。

**虚拟化评测**
性能评测。Specvirt专为KVM开发，使得KVM会更加完善。

**使用方便**
Xen的缺点是如果你需要更新Xen的版本，你需要重新编译整个内核，而且，稍有设置不慎，系统就无法启动。KVM不需要重新编译内核，也不需要对当前kernel做任何修改，它只是几个可以动态加载的.ko模块。它结构更加精简、代码量更小。所以，出错的可能性更小。

# 4. 桌面虚拟化 #

http://www.spice-space.org/home.html

SPICE是去年Red Hat收购Qumranet后获得虚拟技术，被Qumranet使用在其商业虚拟桌面产品SolidIce中。SPICE能用于在服务器和远程计算机如桌面和瘦客户端设备上部署虚拟桌面。它类似于其它用于远程桌面管理的渲染协议，如微软的Remote Desktop Protocol或Citrix的Independent Computing Architecture。
　　
它支持Windows XP、Windows 7和Red Hat Enterprise Linux等虚拟机实例。大部分SPICE代码是采用GNU GPLv2许可证发布，部分代码是采用LGPL许可证。
        
红帽是当今世界上最强大的Linux公司，当然仅限于服务器领域，与此形成鲜明反差的是，它在桌面系统领域几乎可以说是无所作为。现在，这一状况将于2012年得到改观，因为红帽宣布将重新引进一套建立在被称为“独立计算环境初级协议(Simple Protocol for Independent Computing Environments，简称SPICE)之上的虚拟桌面基础架构(简称VDI)。

## 4.1 桌面系统将采用SPICE ##

上述消息并不是说红帽已经完全将有关Linux桌面版系统的相关事宜部署完毕。红帽企业级Linux桌面版目前仍然可用，并且在红帽的庞大商业计划中，桌面系统只是极小的一个组成部分。但这一切现状都可能会改变，很明显红帽如今愿意深入探讨一套针对小型客户的基于服务器的VDI桌面系统。

这一修订版的桌面系统采用SPICE机制，正如微软的远程桌面协议(简称RDP)及Citrix的独立计算架构(ICA)那样，这是一套桌面显示服务协议。这类方案的重点是相同的，即将繁重的运算任务交给服务器完成，而为使用者提供一款小巧低耗的客户机，如此一来，用户会发现自己小巧的客户机在处理问题方面同过往那些庞大的系统一样高效。

这款桌面系统并不会把传统意义上的操作系统，例如即将发布的Ubuntu 11.04或已经发布的Windows 7，当作竞争对手。简化版客户机系统的价值只体现在企业级的运行平台上，例如那些红帽已经在为之提供技术支持的公司。请记住，在Linux服务器(而非桌面系统)方面，红帽已经建立了坚实有力的客户基础。

## 4.2 虚拟化平台的重心——KVM ##

在服务器端，SPICE依靠内核虚拟机(简称KVM)来为大量的任务需求提供强劲的运算能力。猜猜近期红帽将把虚拟化平台的重心放在哪里?无疑正是KVM。因此，如果大家开办了一家公司，而其服务器业务正是由红帽负责的，那么顺水推舟地让他们再提供一套Linux桌面系统互补方案不正是相当有建设性的想法吗?而在这一计划的实施中，没准我们还可以卖掉一些多余的服务器许可来节省开支。这对我个人来说，绝对是非常划算的商务改造计划，而它也能够很好地立足于红帽现有的业务并继续拓展开去。

红帽早先就已经探讨过基于SPICE体系的VDI相关方案，但由于他们发现SPICE这一体系中充斥着不计其数的专有代码，这一计划就暂时搁浅了。正因为红帽公司的服务以开源为前提，因此SPICE这类体系的引入可能会令其服务器处理速度大大下降。

红帽企业虚拟化管理器

正如一位红帽公司的软件工程师在旧金山的Linux基金会协作峰会(Linux Foundation Collaboration Summit)上就红帽SPICE体系向我说明的那样：红帽企业虚拟化管理器 (简称RHVM)，是为以Windows为运行平台的服务器设计的。

没错，就是这么回事。一款以Linux为主体的程序要在Windows环境下才能工作。这，正是我们所能推测到的，红帽至今仍未正式推出不管是基于RHVM还是SPICE的任何桌面系统的原因。正如这位红帽公司的员工所说，“客户大概会向我们问起运行环境方面的情况，而如果我们照实回答‘它得运行在Windows平台的服务器上’，客户们绝对会惊呼‘开玩笑的吧?’”可是，这就是实际情况。

事实上这种改变真的正在悄然发生，尽管速度缓慢。首先，红帽必须从RHVM中“消除那些在Windows系统上可能产生的错误”，而这些可能存在冲突的组件正是在研发时红帽员工添加进去的。这款管理器的下一个版本RHVM 3.0，将于今年年末或明年早些时候推出，会是一款由纯Linux驱动的服务器应用程序。其动态服务器页面(Active Server Page，简称ASP)的相关组件将被替换为Java等可提供相同功能的工具。

将提高SPICE的处理速度

此外，他还谈到红帽正在致力于将SPICE的处理速度提高到其前代产品的水平。“开源SPICE目前能够达到其专用版本处理速度的百分之八十，而我们的目标是让其速度百分之百等同于Fedora 15。”Fedora 15现定于今年五月二十四日发布。对于红帽企业级Linux(简称RHEL)的用户来说，大家可以期待在RHEL 6.2上看到全速运转的SPICE。

将这些信息整理起来不难发现，我们预计可以在2012年初看到一个比较完整的红帽Linux VDI桌面系统。它能够立即取代庞大的传统客户机系统吗?恐怕不行，连红帽公司自身都不指望能做到这一点。但是，正如其提到的，对于商用桌面系统来说“这是针对战术性问题所推出的一种战术性对策”。

就我个人而言，对这款产品还是相当期待的。尽管我自己未必会使用这类简化版的客户机桌面系统，但它对于那些有相关业务需要的工作人员来说还是很有意义的。可以预见，那些已经采用RHEL来管理其服务器的企业将把这款产品当成一种非常自然、能够节约成本、极具拓展性的Linux解决方案，并通过它为行业内部的桌面系统使用者们带来福音。

# 5. 硬件辅助虚拟化 #
硬件辅助虚拟化，顾名思义，就是在CPU、芯片组及 I/O 设备等硬件中加入专门针对虚拟化的支持，使得系统软件可以更加容易

1. vcpu 对应一个 VMCS
2. eager vcpu 切换
    用的话再去更新某个寄存器如 FP Reg.
3. Vt-d 
    直接可以把中断注入 Guest 中去。
4. VCPU 忙等的时候可以调出去。
5. VMCS 中保存 shadow 对应物理 CPU
    Shadow 和 Guest 看到是一样的。

# 6. IO Virtualization #

## 6.1 软件辅助 IO 虚拟化

IO虚拟化：虚拟设备队列VMDq技术解析
　　I/O虚拟化的方法有很多种，现在使用的主要有两种，它们都是纯软件的，它们分别是：设备模拟和额外软件界面，如下图所示：

![](/kvm_blog/img/device_simulator.jpg)

设备模拟：VMM对客户机摸拟一个I/O设备，通过软件完全模拟设备的功能，客户机可以使用对应真实的驱动程序，这个方式可以提供完美的兼容性（而不管这个设备事实上存不存在），但是显然这种模拟会影响到性能。作为例子，各种虚拟机在使用软盘映像提供虚拟软驱的时候，就运行在这样的方式，以及Virtual PC的模拟的真实的S3 Virge 3D显卡，VMware系列模拟的Sound Blaster 16声卡，都属于这种方式，一般的虚拟网卡也是这种方式。


![](/kvm_blog/img/device_interface.jpg)

额外软件界面：这个模型比较像I/O模拟模型，VMM软件将提供一系列直通的设备接口给虚拟机，从而提升了虚拟化效率，这有点像Windows操作系统的DirectX技术，从而提供比I/O模拟模型更好的性能，当然兼容性有所降低，例如VMware模拟的VMware显卡就能提供不错的显示速度，不过不能完全支持DirectDraw技术，Direct3D技术就更不用想了。相似的还有VMware模拟的千兆网卡，等等，这些品牌完全虚拟的设备（例如，VMware牌显卡，VMware牌网卡）需要使用特制的驱动程序部分直接地和主机、硬件通信，比起以前完全模拟的通过虚拟机内的驱动程序访问虚拟机的十兆百兆网卡，可以提供更高的吞吐量。 




## 6.2. 硬件辅助 IO 虚拟化

### 6.2.1 IOMMU
        
从VMware和Xen这样的虚拟管理器(VMM)看出，你可以在不借助硬件的情况下在x86上创建有效的虚拟机。但是解决x86的虚拟化制约问题带来了重要的软件开销——可以通过在较低水平上进行一些架构改造来避免这个开销。
        
AMD的AMD-V硬件虚拟化技术(AMD64扩展)通过提供一种超级权限操作模式为VMM铺下了第一个硬件基础，在这种模式下，VMM可以控制客户操作系统。第二个基础就是对虚拟I/O的硬件支持。AMD在今年二月发布了一项I/O虚拟化规范，透露了一款名为IOMMU(I/O Memory Management Unit)的设备设计。这个设计的实施将成为2007年规划的支持芯片组的一部分。但这些都实现了以后，VMM将能够利用IOMMU硬件从运行在客户操作系统上的软件对物理设备的更快速、更直接以及更安全的访问。
        
现有的VMM必须使用模拟设备将来自客户操作系统的驱动程序路由到VMM。这样做是为了管理对共同内存空间的访问，并闲置对内核模式驱动程序的真实设备访问。AMD的IOMMU设计消除了这些限制，提供DMA地址转换、对设备读取和写入的权限检查。有了IOMMU，客户操作系统中一个未经修改的驱动程序可以直接访问它的目标设备，避免了通过VMM运行产生的开销以及设备模拟。

#### 什么是IOMMU ####

![](/kvm_blog/img/iommu.jpg)

AMD IOMMU：打造高效I/O虚拟化“直通道”  

IOMMU是管理对系统内存的设备访问。它位于外围设备和主机之间，将来自设备请求的地址转换为系统内存地址，并检查每个接入的适当权限。通常情况下，AMD IOMMU是被部署成HyperTransport或者PCI桥接设备的一部分。在高端系统中，CPU和I/O hub之间可能会有多个HyperTransport连接，这时候就需要多个IOMMU。IOMMU可以将设备显示的任何地址转换为一个系统地址。更重要的是，IOMMU提供了一种保护机制，即限制设备对内存的访问，正是地址转译和访问保护的结合让IOMMU对虚拟化具有重要价值。

#### 转译和保护 ####
有了IOMMU，每个设备可以分配到一个保护域。这个保护域定义了I/O页的转译将被用于域中的每个设备，并且明确了每个I/O页的读取权限。对于虚拟化来说，VMM可以指定所有设备分配到相同保护域中的一个特定客户操作系统，这将创建一系列为运行在特定客户操作系统中运行所有设备使用的地址转译和访问限制。IOMMU将页转译缓存在一个TLB(Translation Lookaside Buffer)中。你需要键入保护域和设备请求地址才能进入TLB。因为保护域是缓存密钥的一部分，所以域中的所有设备共享TLB中的缓存地址。IOMMU决定一台设备属于哪个保护域，然后使用这个域和设备请求地址查看TLB。TLB入口包括读写权限标记以及用于转译的目标系统地址，因此如果缓存中出现一个登入的话，许可标记将被用于决定是否允许该访问。对于不在缓存中的地址来说(针对特定域)，IOMMU会继续查看设备相关的I/O页表格。I/O页表格入口也包括连接到系统地址的许可信息。

因此，所有地址转译最重要么是一次成功的查看，这种情况下，适当的权限标记会告诉IOMMU允许还是阻隔访问，要么最终是一次失败的查看。然后，VMM使用IOMMU能够控制哪些系统页对每个设备(或者保护域中的设备组)是可见的，并明确指定每个域中每个页的读写访问权限。这些是通过控制IOMMU用来查看地址的I/O页表格实现的。IOMMU提供的转译和保护双重功能提供了一种完全从用户代码、无需内核模式驱动程序操作设备的方式。IOMMU可以被用于限制用户流程分配的内存设备DMA，而不是使用可靠驱动程序控制对系统内存的访问。设备内存访问仍然是受特权代码保护的，但它是创建I/O页表格(而不是驱动程序)的特权代码。

中断处理程序仍需要在内核模式下运行。利用IOMMU的一种方式是创建一个有限制的、包括中断处理程序的内核模式驱动程序，或者从用户代码控制设备。

#### 直接访问 ####
IOMMU通过允许VMM直接将真实设备分配到客户操作系统让I/O虚拟化更有效。VMM无法模拟IOMMU的转译和保护功能，因为VMM是不能介于运行在客户操作系统上的内核模式驱动程序与底层硬件之间。因此，当缺少IOMMU的时候，VMM会取而代之作为客户操作系统的模拟设备。最后VMM将客户请求转换到运行主机操作系统或者hypervisor的真实驱动程序请求。
有IOMMU，VMM会创建I/O页表格将系统物理地址映射到客户物理地址，为客户操作系统创建一个保护域，然后让客户操作系统入常运转。针对真实设备编写的驱动程序则作为那些未经修改、对底层转译无感知的客户操作系统的一部分而运行。客户I/O交易通过IOMMU的I/O映射被从其他客户独立出来。

IOMMU不支持系统内存需求页，之所以不能是因为外围设备不能被告知重试操作，这个操作要求处理页加载。向那些显示的页面进行的DMA传输可能失败，因此VMM不知道哪个页是DMA目标，锁定内存中的整个客户要求VMM通过IOMM支持外围设备。

显然，AMD的IOMMU在I/O设备虚拟化开销方面有着很大不同：避免设备模拟、取消转译层和允许本机驱动程序直接配合设备。我们很期待VMM在支持这项技术之后将获得怎样的性能结果。

### 6.2.2 硬件 IO 虚拟化 ###
　　
可以看到，这两种纯软件实现的方式有些类似于完全虚拟化和部分虚拟化的分别，不管哪种方式，都是软件实现，转向硬件实现会不会更好呢？ 

![](/kvm_blog/img/software_based_sharing.jpg)

现有方案：基于软件的共享

和处理器上的Intel VT-i和VT-x一样，Intel VT-d技术是一种基于North Bridge北桥芯片（或者按照较新的说法：MCH/IOH）的硬件辅助虚拟化技术，**通过在北桥中内置提供DMA虚拟化和IRQ虚拟化硬件**，实现了新型的I/O虚拟化方式。Intel VT-d技术通过硬件实现的如硬件缓冲、地址翻译等措施，增加了两种设备虚拟化方式：

#### 直接分配 ####
虚拟机直接分配物理I/O设备给虚拟机，这个模型下，虚拟机内部的驱动程序直接和硬件设备直接通信，只需要经过少量，或者不经过VMM的管理。为了系统的健壮性，需要硬件的虚拟化支持，以隔离和保护硬件资源只给指定的虚拟机使用，硬件同时还需要具备多个I/O容器分区来同时为多个虚拟机服务，这个模型几乎完全消除了在VMM中运行驱动程序的需求。例如CPU，虽然CPU不算是通常意义的I/O设备——不过它确实就是通过这种方式分配给虚拟机，当然CPU的资源还处在VMM的管理之下。
![](/kvm_blog/img/direct_assignment.jpg)


#### 原生共享 ####

![](/kvm_blog/img/natively_shared.jpg)

要实现这个功能，设备需要支持PCI SR-IOV规范，并需要系统支持VT-d
原生共享：这个模型是I/O分配模型的一个扩展，对硬件具有很高的要求，需要设备支持多个Function接口，每个接口可以单独分配给一个虚拟机，这个模型无疑可以提供非常高的虚拟化性能表现。

最后这种设备虚拟化方式到了网卡上的实现就是VMDc方式，这种方式上，网卡需要提供多个Function以提供给虚拟机，每个虚拟机直接连接到网卡的Function上，所以叫做Virtual Machine Direct Connect虚拟机直接连接。

#### VMDc ####

VMDc利用SR-IOV功能将虚拟机的虚拟网卡直接映射到物理网卡的Virtual Function上支持VMDc技术的网卡提供了多个Function，Function有两类：Physical Function（用来配制管理网卡）和Virtual Function，每一个虚拟机都可以映射到一个Virtual Function，不同的虚拟机使用不同的Virtual Function，从而提供了充足的性能以及虚拟机隔离能力。

![](/kvm_blog/img/mapping_vf_configuration.jpg)

# 7. Xen 原理介绍
## 7.1 各种 guest 类型
Xen_PVM

![](/kvm_blog/files/virt_intro/xen_pvm.png)

Xen PV

![](/kvm_blog/files/virt_intro/xen_pv.png)

Xen HVM

![](/kvm_blog/files/virt_intro/xen_hvm.png)

## 7.2 全虚（同步）： ##
 
![](/kvm_blog/files/virt_intro/xen_full_virt.png)

- DomU的IN/OUT指令触发VMExit，由 Xen Hypervisor设置的 VMExit 函数进行处理。
- Xen Hypervisor将 I/O指令的具体信息写入 DomU和Dom0设备模型DM的共享页（Share Page），通过事件驱动通知 Dom0。
- Dom0内核收集DomU的 I/O请求。
- Dom0从内核态返回到用户态，进入DM进行处理。
- DM读取 I/O共享页，识别是哪类外设的访问，根据不同的请求，将虚拟的外设的状态写回 I/O共享页，或调用驱动访问硬件，发生一次真正的数据复制，并通过事件通道通知Xen Hypervisor处理完毕；Xen Hypervisor得到通知后，解除发生 I/O请求的DomU的阻塞。当DomU再次被调度后，可以得到 I/O请求的结果。

代码解析： qemu代码

	-- vl.c main()-->
	    --> helper2.c main_loop() （注册函数 cpu_handle_ioreq() ）
	        --> helper2.c main_loop_wait(1) 等 1/1000 秒查询是否有事件通道请求 
	    -----------------------------------
	    --> cpu_handle_ioreq() 
	        --> __handle_buffered_iopage(env)
	        --> __handle_ioreq(env, req)
  

	vmx_vmexit_handler--》handle_mmio--》hvm_emulate_one--》x86_emulate--》hvmemul_read--》__hvmemul_read--》hvmemul_do_mmio
	--》hvmemul_do_io
	
	vmx_vmexit_handler
	    case EXIT_REASON_IO_INSTRUCTION://hhb mmio and pio
	        exit_qualification = __vmread(EXIT_QUALIFICATION);
	        if ( exit_qualification & 0x10 )
	        {
	            /* INS, OUTS */
	            if ( !handle_mmio() )
	                hvm_inject_hw_exception(TRAP_gp_fault, 0);
	        }
	        else
	        {
	            /* IN, OUT */
	            uint16_t port = (exit_qualification >> 16) & 0xFFFF;
	            int bytes = (exit_qualification & 0x07) + 1;
	            int dir = (exit_qualification & 0x08) ? IOREQ_READ : IOREQ_WRITE;
	            if ( handle_pio(port, bytes, dir) )
	                update_guest_eip(); /* Safe: IN, OUT */
	        }
	        break;
	
	--1.1-handle_mmio----------
	/ put_page用来完成物理页面与一个线性地址页面的挂接，从而将一个
	// 线性地址空间内的页面落实到物理地址空间内，copy_page_tables函数
	// 只是为一个进程提供了在线性地址空间的一个页表及1024页内存，而当时
	// 并未将其对应的物理内存上。put_page函数则负责为copy_page_tables开
	// 的“空头支票”买单。
	// page为物理地址，address为线性地址
	
	int handle_mmio(void)
	{
	    struct hvm_emulate_ctxt ctxt;
	    struct vcpu *curr = current;
	    struct hvm_vcpu_io *vio = &curr->arch.hvm_vcpu.hvm_io;
	    int rc;
	
	    hvm_emulate_prepare(&ctxt, guest_cpu_user_regs());
	
	    rc = hvm_emulate_one(&ctxt);        // 模拟 MMIO指令
	
	    if ( rc != X86EMUL_RETRY )
	        vio->io_state = HVMIO_none;
	    if ( vio->io_state == HVMIO_awaiting_completion )
	        vio->io_state = HVMIO_handle_mmio_awaiting_completion;
	    else
	        vio->mmio_gva = 0;
	
	    switch ( rc )
	    {
	    case X86EMUL_UNHANDLEABLE:
	        gdprintk(XENLOG_WARNING,
	                 "MMIO emulation failed @ %04x:%lx: "
	                 "%02x %02x %02x %02x %02x %02x %02x %02x %02x %02x\n",
	                 hvmemul_get_seg_reg(x86_seg_cs, &ctxt)->sel,
	                 ctxt.insn_buf_eip,
	                 ctxt.insn_buf[0], ctxt.insn_buf[1],
	                 ctxt.insn_buf[2], ctxt.insn_buf[3],
	                 ctxt.insn_buf[4], ctxt.insn_buf[5],
	                 ctxt.insn_buf[6], ctxt.insn_buf[7],
	                 ctxt.insn_buf[8], ctxt.insn_buf[9]);
	        return 0;
	    case X86EMUL_EXCEPTION:
	        if ( ctxt.exn_pending )
	            hvm_inject_hw_exception(ctxt.exn_vector, ctxt.exn_error_code);
	        break;
	    default:
	        break;
	    }
	
	    hvm_emulate_writeback(&ctxt);
	
	    return 1;
	}
	
	int handle_mmio_with_translation(unsigned long gva, unsigned long gpfn)
	{
	    struct hvm_vcpu_io *vio = &current->arch.hvm_vcpu.hvm_io;
	    vio->mmio_gva = gva & PAGE_MASK;
	    vio->mmio_gpfn = gpfn;
	    return handle_mmio();
	}
	
	int handle_pio(uint16_t port, int size, int dir)
	{
	    struct vcpu *curr = current;
	    struct hvm_vcpu_io *vio = &curr->arch.hvm_vcpu.hvm_io;
	    unsigned long data, reps = 1;
	    int rc;
	
	    if ( dir == IOREQ_WRITE )
	        data = guest_cpu_user_regs()->eax;
	
	    rc = hvmemul_do_pio(port, &reps, size, 0, dir, 0, &data);
	
	    switch ( rc )
	    {
	    case X86EMUL_OKAY:
	        if ( dir == IOREQ_READ )
	            memcpy(&guest_cpu_user_regs()->eax, &data, vio->io_size);
	        break;
	    case X86EMUL_RETRY:
	        if ( vio->io_state != HVMIO_awaiting_completion )
	            return 0;
	        /* Completion in hvm_io_assist() with no re-emulation required. */
	        ASSERT(dir == IOREQ_READ);
	        vio->io_state = HVMIO_handle_pio_awaiting_completion;
	        break;
	    default:
	        gdprintk(XENLOG_ERR, "Weird HVM ioemulation status %d.\n", rc);
	        domain_crash(curr->domain);
	        break;
	    }
	
	    return 1;
	}


--1.2-handle_pio ------------      

## 7.3 半虚（异步）： ##

![](/kvm_blog/files/virt_intro/xen_para_virt.png)

- DomU的应用程序访问虚拟 I/O设备，DomU内核调用对应的前端驱动，前端驱动产生 I/O请求，该请求描述了要写入数据的地址及长度。
- 前端驱动将要写入的数据放入授权表，给Dom0访问的权限。
- 前端驱动通过事件通道通知Dom0。
- Dom0检查事件，发现有新的 I/O请求，调用后端驱动进行处理。
- 后端驱动从共享环中取出 I/O请求对应的数据地址和长度。
- 后端驱动通过授权表的操作取得DomU要写入的数据。
- 后端驱动将 I/O请求预处理后调用真实的设备驱动执行写入操作。
- I/O请求完成后，后端驱动产生 I/O响应，并将其放入共享环，并通过事件驱动机制通知 DomU。
- Xen Hypervisor 调度DomU运行时，检查事件，发现有新的 I/O响应，则为DomU产生模拟中断。
- 中断处理函数检查事件通道，并根据具体的事件调用对应前端驱动的响应处理函数。
- 前端驱动从共享环中读出 I/O响应，并处理 I/O响应。

总结：IO共享环的作用是具体的IO请求（如发送网络数据），是请求！事件通道是通知用的！授权表指向的内存是数据的存储地！举个不十分恰当的例子：A（DomU）请B（Dom0）帮忙保存一些贵重物品S（数据），首先A写一张纸条（IO共享环），上面说明请求B帮忙做的事情，放到B的门口，然后敲门（事件通道）。B听到敲门（事件通道的中断）后开门看到纸条（IO共享环），分析上面的内容后，去到A固有的地点（授权表上写明的内存地址）取物品S。一切做完后写个纸条（IO共享环）贴到A门口，敲门（事件通道）。

**后端：**
        
当后端检测到新出现的即插即用的设备时，会调用预先注册的 .probe 函数，如：blkback_probe，在该函数中会调用 xenbus_watch_path2函数，将backend_changed置为回调函数。当检测到 xenstore中后端信息变化时，就会调用 backend_changed。

**前段：**
        
前端设备在DomU中进行注册，类似于后端设备。以块设备为例，前端会调用 blkfront_probe() 函数来完成块设备前端初始化，在该函数最后会调用 talk_to_backend函数建立前后端的连接。在执行完 setup_blkring() 函数后，talk_to_backend() 会将授权表引用信息写入 xenstore中，并将自身状态变为 XenbusStateInitialised。
        
当 XenBus检测到前端状态发生变化时，会自动调用后端回调函数 frontend_changed()，在该函数中调用 connect_ring 取得前端共享页面的引用以及事件通道端口号，并将 XenbusStateConnected。至此，后端到前端的连接已经建立。
        
当 XenBus检测到后端状态发生变化时，调用前端的回调函数 backend_changed() , 最后调用函数 connect()。至此，前端至后端的连接也已经建立。
 
