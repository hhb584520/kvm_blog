本节主要介绍几个较小但同样非常有用的特性，如 1GB 大页内存的使用、透明大页、AVX和XSAVE指令的支持、AES新指令的支持、完全暴露宿主机 CPU 的特性。

# 1. 1GB大页 #
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


# 2. 透明大页 #

使用大页可以提高系统内存的使用效率和性能，不过大页有如下几个缺点：
    
1) 大页必须在使用前就预留下来（1GB 大页还只能在启动时分配）。  
2) 应用程序代码必须显式使用大页（一般是调用 libhugetlbfs API 来分配大页）。  
3) 大页必须常驻物理内存中，不能给交换到交换分区中。  
4) 需要超级用户权限来挂载 hugetlbfs文件系统。  
5) 如果预留了大页内存但没有实际使用就会造成物理内存的浪费。  

透明大页（Transparent Hugepage）正是发挥了大页的一些优点，又能避免了上述缺点。 透明大页，如它的名词描述的一样，对所有应用程序都是透明的，应用程序不需要任何修改即可享受透明大页带来的好处。在使用透明大页时，普通的使用 hugetlbfs 大页依然可以正常使用，而在没有普通的大页可供使用时，才使用透明大页。透明大页时可交换的，当需要交换到交换空间时，透明的大页被打碎为常规的 4KB 大小的内存页。在使用透明大页时，如果因为内存碎片导致大页内存分配失败，这时系统可以优雅地使用常规的 4KB 页替换，而且不会发生任何错误、故障或用户态的通知。而当系统内存较为充裕、有
很多的大页面可用时，常规的页分配的物理内存可以通过 khugepaged 进程自动迁往透明大页内存。内核进程 khugepaged的作用是，扫描正在运行的进程，然后试图将使用的常规内存页转换到使用大页。目前，透明大页仅仅支持匿名内存的映射，对磁盘缓存和共享内存的透明大页支持还处于开发之中。

使用透明大页的步骤如下：
1) 在编译 Linux 内核时，配置好透明大页的支持，配置文件中的示例如下：

    CONFIG_TRANSPARENT_HUGEPAGE=y
    CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=y
    # CONFIG_TRANSPARENT_HUGEPAGE_MADVISE is not set
    这表示默认对所有应用程序的内存分配都尽可能地使用透明大页。当然，还可以在系统启动时修改 Linux 内核的启动参数来调整这个默认值（transparent_hugepage），其取值为如下 3 个值之一：
        transparent_hugepage=[always|madvise|never]

2) 在运行的宿主机中配置透明大页的使用方式，命令行如下

    # cat /sys/kernel/mm/transparent_hugepage/enabled
    # cat /sys/kernel/mm/transparent_hugepage/defrag
    # cat /sys/kernel/mm/transparent_hugepage/khugepage/defrag
    # echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
    # cat /sys/kernel/mm/transparent_hugepage/defrag
        
 /sys/kernel/mm/transparent_hugepage/enabled 接口的值为 always，表示尽可能地在内存分配中使用透明大页。
 /sys/kernel/mm/transparent_hugepage/defrag接口是表示系统在发生页故障（page  fault）时同步地做内存碎片的整理工作，其运行的频率较高（某些情况下会带来额外的负担）；
 /sys/kernel/mm/transparent_hugepage/khugepage/defrag 接口表示在 khugepaged 进程运行时进行内存碎片的整理工作它的运行频率较低。
 当然还可以在 KVM 客户机中也使用透明大页，这样在宿主机和客户机同事使用的情况下，更容易提高内存使用的性能。

3) 查看 系统使用透明大页的效果

    # cat /proc/meminfo | grep -i AnonHugePages
        AnonHugePages:   688128 KB
    # echo $((688128/2048))
    
关于透明大页的使用，这里有一篇文章：
     https://access.redhat.com/solutions/46111
    

# 3. AVX和XSAVE指令 #
AVX(Advanced Vector Extensions，高级矢量扩展)是Intel 和AMD的x86 架构指令集的一个扩展，2011年Intel 发布Sandy Bridge处理器时开始第一次正式支持 AVX. AVX 中的新特性有：将向量化宽度从128位提升到256位，且将 XMM0~XMM15寄存器重命名为 YMM0~YMM15；引入了三操作数、四操作数的 SIMD 指令格式；弱化了对 SIMD 指令中对内存操作对齐的要求，支持灵活的不对齐内存地址访问。
    
向量就是多个标量的组合，通常意味着SIMD（单指令多数据），就是一个指令同时对多个数据进行处理，达到很大的吞吐量。MMX(多媒体扩展 64bits)--SSE(流式 SIMD 扩展 128bits).另外，XSAVE 指令（包括 XSAVE, XRSTOR等）是在 Intel Nehalem处理器中开始引入的，是为了保存和恢复处理器
扩展状态的，在AVX引入后，XSAVE 也要处理 YMM 寄存器状态。在KVM虚拟化环境中，客户机的动态迁移需要保存处理器状态，然后迁移后恢复处理器的执行状态，如果有AVX指令要执行，在保存和恢复时也需要 XSAVE, XRSTOR 指令的支持。
   
下面介绍以下如何在KVM中为客户机提供 AVX、XSAVE 特性。
1)  检查宿主机中 AVX、XSAVE 的支持，Sandy之后硬件平台都支持，较新的内核（如3.x）也支持。

    # cat /proc/cpuinfo | grep avx | grep xsave

2) 启动客户机，将 AVX、XSAVE 特性提供客户机使用，命令行操作如下：

    # qemu-system-x86_64 -smp 2 -m 1024 rhel6u3.img -cpu host -net nic -net tap

3) 在客户机中，查看 QEMU 提供的CPU信息中是否支持 AVX和XSAVE，命令行如下：

    # cat /proc/cpuinfo | grep avx |  grep xsave

另外，Intel 在Haswell 平台将会引入新的指令集 AVX2，它将会提供包括支持 256 位向量的整数运算在内的更多功能用 -cpu host 参数也可以将 AVX2 的特性提供给客户机使用。 


# 4. AES新指令 #

AES (Advanced Encryption Standard, 高级加密标准，AES的区块长度固定为 128位，密钥长度则可以是128、192或256位。

AES-NI  (Advanced Encryption Standard new instructions) 是 Intel 在2008年提出的在 x86处理器上的指令集扩展它包括7条新指令，并且从 Westmere 就开始支持了。
    
测试流程如下：  
1) 检查 BIOS是否支持 AES  
2) 确认编译了 AES 模块。

    CONFIG_CRYPTO_AES=m
    CONFIG_CRYPTO_AES_X86_64=m
    CONFIG_CRYPTO_AES_NI_INTEL=m

3) 在宿主机中，查看 /proc/cpuinfo 中的 AES-NI 相关的特性，并加载 aesni_intel

    # cat /proc/cpuinfo | grep aes
    # lsmod | grep aes
    # modprobe aesni_intel
    # lsmod | grep aes

    modprobe aesni_intel
    FATAL: Error inserting aesni_intel  说明硬件不支持AES-NI或是BIOS屏蔽了AES-NI特性造成FATAL: Module aesni_intel not found  说明 aesni_intel 模块没有正确编译
    
4) 启动客户机
    # qemu-system-x86_64 -smp 4 -m 4096 rhel6u3.img -cpu host
    or
    # qemu-system-x86_64 -smp 4 -m 4096 rhel6u3.img -cpu qemu64.+aes  

# 5. 完全暴露宿主机 CPU 的特性 #












