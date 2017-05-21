# 1. Huge Page 介绍
X86(包括 x86-32 和 x86-64)架构的CPU默认使用 4KB 大小的内存页面，但是它们支持较大的内存页，如x86_64 系统就支持 2MB大小的大页。linux2.6及以后的内核都支持 huge page。如果在系统中使用了 huge page，则内存页的数量会减少，从而要更少的页表，节约了页表所占用的内存数量，并且所需的地址转换也减少了 TLB 缓存失效的次数就减少了，从而提高了内存访问的性能。另外，由于地址转换所需的信息一般保存在 CPU的缓存中， huge page 的使用让地址转换信息减少，从而减少了CPU 缓存的使用，减轻了 CPU的缓存的压力，让 CPU 缓存能更多地用于应用程序的数据缓存，也能够在整体上提升系统的性能。

在KVM中，也可以将 huge page 的特性应用到客户机中

	[root@kvm haibin]# qemu-system-x86_64 --help | grep mem
	-m [size=]megs[,slots=n,maxmem=size]
	                size: initial amount of guest memory
	                maxmem: maximum amount of guest memory (default: none)
	-mem-path FILE  provide backing storage for guest RAM
	-mem-prealloc   preallocate guest memory (use with -mem-path)

提前分配好内存的好处就是客户机的内存访问速度更快，缺点是客户机启动时就得到了所有的内存，从而让宿主机的内存很快减少了（而不是根据客户机的需求而动态调整内存分配）

# 2. Huge Page 使用

## 2.1 check host hugepage
         
	# getconf PAGESIZE
	4096
         
	# cat /proc/meminfo
	……
	HugePages_Total:       0
	HugePages_Free:        0
	HugePages_Rsvd:        0
	HugePages_Surp:        0
	Hugepagesize:       2048 kB
	DirectMap4k:      339272 kB
	DirectMap2M:     4806656 kB
	DirectMap1G:    131072000 kB
     
## 2.2 mount hugetlbfs       
         
	# mount -t hugetlbfs hugetlbfs /dev/hugepages

	[root@kvm-build rpmrepo]# mount
	......
	/dev/mapper/rhel-root on / type xfs (rw,relatime,attr2,inode64,noquota)
	hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime)



## 2.3 set hugetlbfs  num 
       
	# sysctl vm.nr_hugepages=1024
	……
	HugePages_Total:    1024
	HugePages_Free:     1024
	HugePages_Rsvd:        0
	HugePages_Surp:        0
	Hugepagesize:       2048 kB
	DirectMap4k:      341320 kB
	DirectMap2M:     4804608 kB
	DirectMap1G:    131072000 kB

	# cat /proc/meminfo

## 2.4 Create guest   
      
    # vim  ./kvm-rhel7-hugepages.sh
	# !/bin/sh
	qemu-system-x86_64 -enable-kvm -m 4096 -smp 4  -spp on -monitor pty -cpu host \
	-device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
	-netdev tap,id=nic0,script=/etc/kvm/qemu-ifup \
	-drive file=/share/xvs/var/rhel7.qcow,if=none,id=virtio-disk0 \
	-device virtio-blk-pci,drive=virtio-disk0 \
	-mem-path /dev/hugepages

    qemu-system-x86_64 -m 1024 -smp 2 rhel6u3.img -mem-path /dev/hugepages -mem-prealloc 
    comment: -mem-prealloc 预先分配好

## 2.5 查看host huge page

	# cat /proc/meminfo
	……
	HugePages_Total:    1024
	HugePages_Free:      897
	HugePages_Rsvd:      393
	HugePages_Surp:        0
	Hugepagesize:       2048 kB
	DirectMap4k:      341320 kB
	DirectMap2M:     4804608 kB
	DirectMap1G:    131072000 kB

可以看到 HugePages_Free 数量减少，因为客户机使用了一定数量的 hugepages。在如下的输出中，HugePages_Free数量的减少没有 512（512×2MB=1024MB）那么多，这是因为启动客户机时并没有实际分配 1024MB 内存，上面提到 -mem-prealloc 参数就会让 meminfo 文件中 HugePages_Free 的数量减少和分配给客户机的一致。

总的来说，对于内存访问密集型的应用，在KVM客户机中使用 huge page 是可以比较明显地提高客户机性能的，不过，它也有一个缺点，使用 huge page 的内存不能被 swap out，也不能使用 ballooning 方式自动增长。

缺点：使用 Huge page 的内存不能被换出，也不能使用 ballooning 方式自动增长

# 3. 1GB大页 #
前面介绍的 大页主要是针对 x86_64 CPU 架构上的 2MB 大小的大页，本节将介绍更大的大页—— 1GB大页，这两者的基本用法和原理是大同小异的。总的来说 1GB 大页和 2MB大页一样，使用了 hugetlbfs(一个基于内存的特殊文件系统)来直接利用硬件提供的大页支持，以便创建共享的或私有的内存映射，这样减少了内存页的数量，提高了 TLB缓存的效率，从而提高了系统的内存访问的性能。

1GB 和 2MB 大页的不同点，主要在于它们的内存页大小不同，且1GB大页的分配只能在Linux系统的内核启动参数中指定，而2MB 大页既可以在启动时内核参数配置，又可以在系统运行中用命令行操作来配置。

下面是KVM环境中1GB大页的具体操作步骤。

1) 检查硬件和内核配置对 1GB 大页的支持，命令行如下：

    # cat /proc/cpuinfo | grep pdpe1gb
    # grep HUGETLB /boot/config-3.5.0
    
2) 在宿主机的内核启动参数中配置 1GB，例如，在启动时使用6个1GB大页的 grub 配置文件如下:
       
	title KVM Demo
        root (hd0,0)
        kernel (hd0,0) /boot/vmlinuz-3.5.0 ro root=/dev/sda1 hugepagesz=1GB hugepages=6 default_hugepagesz=1GB

default_hugepagesz ： 该值如果不设置，默认值为2MB
hugepagesz 和 hugepages 选项可以成对地多次使用，可以让系统在启动时同时保留多个大小不同的大页 例如：

     hugepagesz=1GB hugepages=6 default_hugepagesz=1GB hugepagesz=2MB hugepages=512

3) 在启动宿主机后，在宿主机中查看内存信息和内存大页信息，命令行如下：

    # cat /proc/meminfo
    # hugeadm --pool-list

4) 挂载 hugetlbfs 文件系统
    
	# mount -t hugetlbfs hugetlbfs /dev/hugepages
    也可以使用 pagesize 来指定挂载的页的大小
    # mount -t hugetlbfs hugetlbfs /dev/hugepages -o pagesize=2MB
5) 使用 qemu-kvm 命令启动客户机

    # qemu-system-x86_64 -m 6G -smp 2 rhel6u3.qcow -net nic -net tap -mem-path /dev/hugepages/
    在使用 1GB 大页时，笔者发现，启动客户机的内存不能超过 -mem-path 指定的目录的 1GB 大页的内存量，否则可能会出现 “can'tmmap RAM pages: Cannot allocate memory" 的错信息，从而不会为客户机提供任何大页的实际支持。
    
6) 再次查看内存情况

    # cat /proc/meminfo
    由于对大页的支持需要显式调用 libhugetlb 库函数，实际使用大页的程序并不多。
    和 2MB 大页一样，使用 1GB 的大页时，存在的问题也是一开始就需要预留大页的内存，不能 swap，不能 ballooning。

# 3. 参考资料

https://www.ibm.com/developerworks/cn/linux/l-cn-hugetlb/   
关于hugetlb的使用, 参见: https://www.kernel.org/doc/Documentation/vm/hugetlbpage.txt 
KVM虚拟化技术实战与原理解析 任永杰 单海涛 著