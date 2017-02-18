## 1. 内存设置基本参数 ##
(1) -m megs 参数

[root@skl-sp2 ~]# qemu-system-x86_64 -m ?
qemu-system-x86_64: -m ?: Parameter 'size' expects a size
You may use k, M, G or T suffixes for kilobytes, megabytes, gigabytes and terabytes.
默认单位 MB，也可以使用 G 来表示GB单位的内存大小，如“-m 4G”表示 4GB 内存大小。

这里看到的内存都不准，主要是该命令显示的大小是总内存除去了内核执行文件占用内存和一些系统保留的内存之后能使用的内存
cat /proc/meminfo
free -m真实的内存大小
dmesg | grep Memory

(2) -mem-path path  参数
     启动时即分配全部的内存，而不是根据客户机请求而动态分配内存，主要是分配大页内存如 “-mem-path /dev/hugepages”。

(3) -mem-prealloc  参数
      启动时即分配全部的内存，而不是根据客户机请求而动态分配，必须与 "-mem-path"参数一起使用。

(4) -balloon 开启内存气球的设置
     “-balloon virtio”为客户机提供 virtio_balloon 设备，从而通过内存气球 balloon, 可以在QEMU monitor 中用
"balloon" 命令来调节客户机占用内存的大小（-m 参数设置的内存范围内）。


## 2. EPT和VPID简介 ##

CR3 将客户机程序所见的客户机虚拟地址（GVA）转化为客户机物理地址（GPA），然后再通过 EPT 将客户机物理地址（GPA）转化为宿主机物理地址（HPA）。这两次地址转换都是由硬件来完成，其转换效率非常高。还有以下好处和影子页表比

-  很少 VM-Exit，客户机的 Page Fault 、INVLPG(使TLB项目失效)指令、CR3寄存器的访问等都不会引起 VM-Exit
-  EPT 只需要维护一张 EPT 页表，占用内存很少。

VPID（虚拟处理器标识），是在硬件上对 TLB 资源管理的优化，通过在硬件上为每个 TLB 项增加一个标识，用于不同的虚拟处理器的地址空间，从而能够区分开 Hypervisor 和不同处理器的 TLB。在VM-Exit是可以不让 TLB全部失效；提高了VM切换的效率。

默认已经支持，我们也可以用如下命令查看：

    [root@skl-sp2 ~]# cat /sys/module/kvm_intel/parameters/ept
    Y
    [root@skl-sp2 ~]# cat /sys/module/kvm_intel/parameters/vpid
    Y

## 3. 大页（Huge Page） ##

缺点：使用 Huge page 的内存不能被换出，也不能使用 ballooning 方式自动增长

## 3.1 检查宿主机目前的状态 ###

    getconf PAGESIZE   // 检查页大小
    cat /proc/meminfo// 检查内存使用情况

### 3.2 挂载 hugetlbfs ###

    mount -t hugetlbfs hugetlbfs /dev/hugepages

### 3.3 设置 hugepage 的数量 ###

    sysctl vm.nr_hugepages=1024
    cat /proc/meminfo


### 3.4 启动虚拟机 ###

    qemu-system-x86_64 -m 1024 -smp 2 rhel6u3.img -mem-path /dev/hugepages -mem-prealloc 
    comment: -mem-prealloc 预先分配好

## 4. 内存过载使用 ##

    内存交换、气球（balloon）、页共享（KSM）

## 5. Numa ##

## 5.1 KVM Numa ##
qemu-system-x86_64 \
-enable-kvm \
-drive format=raw,file=/root/vdisk.img,index=0,media=disk \
-cpu host \
-m 20480 \
-smp cpus=64,cors=64,threads=1,sockets=1 \
-object memory-backend-ram,size=10240M,host-nodes=0,policy=bind,id=node0 \
-numa node,nodeid=0,cpus=0-63,memdev=node0 \
-object memory-backend-ram,size=10240M,host-nodes=1,policy=bind,id=node1 \
-numa node,nodeid=1,memdev=node1 \
-acpitable file=/sys/firmware/acpi/tables/PMTT 

## 5.2 Xen Numa ##
** Xen Hypervisor**

Compile and install latest Xen. RH 7.2 is preferable dom0 OS.
Add `dom0_mem=2048M,max:4096M` to Xen boot command line to limit dom0 memory occupation.
Reboot and boot Xen.
`xl info –n` to check whether hypervisor can see 2 nodes in Quadrant Mode (8 nodes in SNC-4 Mode).
 
** Build guest with vNUMA**
 
In guest configuration file, add something like:

```
memory=2048
vnuma = [ [“pnode=0”, “vcpus=0-3”, “size=1024”, “vdistance10, 31”], [“pnode=1”, “size=1024”, “vdistance=31, 10”] ]
```
Normally you can use the values from "xl info -n" or "numactl -H" to fill size and vdistance list.
Here, detail the parameters:
 
vnuma=[ VNODE_SPEC, VNODE_SPEC, ... ]

   Specify virtual NUMA configuration with positional arguments. The
   nth VNODE_SPEC in the list specifies the configuration of nth
   virtual node.

   Note that virtual NUMA for PV guest is not yet supported, because
   there is an issue with cpuid handling that affects PV virtual NUMA.
   Furthermore, guests with virtual NUMA cannot be saved or migrated
   because the migration stream does not preserve node information.

   Each VNODE_SPEC is a list, which has a form of
   "[VNODE_CONFIG_OPTION,VNODE_CONFIG_OPTION, ... ]"  (without
   quotes).

   For example vnuma = [
   ["pnode=0","size=512","vcpus=0-4","vdistances=10,20"] ] means vnode
   0 is mapped to pnode 0, has 512MB ram, has vcpus 0 to 4, the
   distance to itself is 10 and the distance to vnode 1 is 20.

   Each VNODE_CONFIG_OPTION is a quoted key=value pair. Supported
   VNODE_CONFIG_OPTIONs are (they are all mandatory at the moment):

   pnode=NUMBER

       Specify which physical node this virtual node maps to.

   size=MBYTES

       Specify the size of this virtual node. The sum of memory size
       of all vnodes will become maxmem=. If maxmem= is specified
       separately, a check is performed to make sure the sum of all
       vnode memory matches maxmem=.

   vcpus=CPU-STRING

       Specify which vcpus belong to this node. CPU-STRING is a string
       separated by comma. You can specify range and single cpu. An
       example is "vcpus=0-5,8", which means you specify vcpu 0 to
       vcpu 5, and vcpu 8.

   vdistances=NUMBER, NUMBER, ...

       Specify virtual distance from this node to all nodes (including
       itself) with positional arguments. For example,
       "vdistance=10,20" for vnode 0 means the distance from vnode 0
       to vnode 0 is 10, from vnode 0 to vnode 1 is 20. The number of
       arguments supplied must match the total number of vnodes.