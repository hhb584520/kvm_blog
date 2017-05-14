# 1. Native Device
## 1.1 IO 寄存器
### 1.1.1 PIO(Port IO)

### 1.1.2 MMIO(Memory-mapped I/O)


## 1.2 Interrupt
### 1.2.1 PIC(8259)

### 1.2.2 APIC(Local/IO APIC)

### 1.2.3 MSI/MSI-x(Message Signaled Interrupt)


## 1.3 DMA
### 1.3.1 DMA read

https://blog.packagecloud.io/eng/2017/02/06/monitoring-tuning-linux-networking-stack-sending-data/
用DMA模块，其中一个DMA通道1用来装载SPI传输TX数据（触发源为SPI TFFF符号，SPI FIFO可装载），另外一个DMA通道0用来接收SPI数据（触发源为SPI RFDF符号，SPI 接收FIFO非空）。通过使用DMA引擎可以自动发起SPI传输，减少内核在SPI传输过程中的干预，达到降低内核工作负荷的效果。SPI模块采用中断方式。

### 1.3.2 DMA write

当有新的数据包来的时候，网卡通过 DMA 将数据写入 RAM (ring buffer), 触发软中断，接着网卡驱动中的 IRQ handler 被调用。
https://blog.packagecloud.io/eng/2016/06/22/monitoring-tuning-linux-networking-stack-receiving-data/#data-arrives

# 2. Device Virtualization
现在的虚拟设备大部分都是采用前后端模型，前文提到的每种资源都可以采用下面的方法进行虚拟化。故应该有9种组合。
我们可以看看下图中实际 qemu 模拟设备。

![](/kvm_blog/img/i440fx.png)
 
## 2.1 方法
- 软件模拟
- PV(Para-virtualization)
- Pass-thru(Device assignment / Direct IO)

## 2.2 多路复用
大部分设备需要做是在后端进行模拟，当然复用也主要在后端完成。Host 大部分已经可以实现了(Disk=>File System/Volume; Network=>Socket/Bridge).

有些设备确实不能做多路复用，比如串口，我们可以在 host 段将数据加上 guest 标签，然后客户端开发一个特殊的软件来解析这个特别的串口数据。

## 2.3 各种资源虚拟化
### 2.3.1 IO 寄存器
- 硬件支持：VMCS: IO bitmap, EPT
- 虚拟化方法
	- 软件模拟（PIO: trap with IO bitmap; MMIO: trap with EPT/Shadow page table）
	- PV(Hypercall)
	- Pass-thru(PIO: Mostly impossible; MMIO: Map with EPT/Shadow page table)

 
### 2.3.2 中断
- 硬件支持
	- VMCS: Interrupt inject field.
	- Virtual APIC
	- VTD: Interrupt Remapping
	- VTD: Interrupt Posting
- 虚拟化方法
	- 软件模拟（Inject with VM entry field; Virtual APIC/Interrupt Remapping）
	- PV(Hypercall)
	- Pass-thru(Interrupt Posting)

### 2.3.2 DMA
- 硬件支持：VTD (DMA Remapping)
- 虚拟化方法
	- 软件模拟（Trap DMA related IO register）
	- PV(Hypercall)
	- Pass-thru(DMA Remapping)

![](/kvm_blog/img/iommu.png)

客户机直接操作设备面临如下问题：
- 如何让客户机直接访问到设备真实的 I/O 地址空间（包括端口 I/O 和 MMIO）
- 如何让设备的 DMA 操作直接访问到客户机的内存空间？要知道，设备可不管系统中运行的是虚拟机还是真实操作系统，它只管用驱动提供给它的物理地址做 DMA.

问题一可以通过 VT-x 技术解决，而问题二则需要通过 VT-d 的 DMA remapping 解决。IO页表是DMA重映射硬件进行地址转换的核心。它的思想和 CPU中 paging 机制的页表类似，与之不同的是，CPU通过CR3寄存器就可以获得当前系统使用的页表的基地址，而 VT-d 需要借助上一节中介绍根条目和上下文条目才能获得设备对应的 IO 页表。通过 IO页表中 GPA 到 MPA的映射，DMA重映射硬件可以将 DMA 传输中的 GPA 转换成 MPA，从而使设备直接访问指定客户机的内存区域。

## 2.4 KVM 实现
### 2.4.1 Emulation in Qemu


### 2.4.2 VirtIO/Vhost


### 2.4.3 Pass-thru
    legacy service assign/vfio/sriov