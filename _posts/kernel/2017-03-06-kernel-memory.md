# 1. 内存地址转换 #


![](/kvm_blog/files/kernel/address_v2p.png)


# 2. 内存地址布局
﻿﻿
预备知识--程序的内存分配， 一个由 C/C++ 编译的程序占用的内存分为以下几个部分：

- 程序代码区，存放函数体的二进制代码。
- 全局区（静态区），全局变量和静态变量的存储是放在一块的，初始化的全局变量和静态变量在一块区域，未初始化的全局变量和静态变量在相邻的另一块区域。程序结束后由系统释放。
- 堆区，一般由程序员分配释放，若程序员不释放，程序结束时可能由OS回收。注意它与数据结构中的堆是两回事，分配方式倒是类似于链表。
- 栈区，由编译器自动分配释放，存放函数的参数值，局部变量的值等。其操作方式类似数据结构中的栈。
- 文字变量区，常量字符串就是放在这里的。程序结束后由系统释放。

![](/kvm_blog/files/kernel/process_address_space.png)

用户进程地址空间的内存地址分配可以通过 pmap命令查看。你也可以通过ps命令显示总的段大小。
这是一个前辈写的，非常详细

	//main.cpp 
	int a = 0; 全局初始化区
	char *p1; 全局未初始化区
	main() 
	{ 
	    int b; 栈
	    char s[] = "abc"; 栈
	    char *p2; 栈
	    char *p3 = "123456"; 123456\0在常量区，p3在栈上。
	    static int c =0； 全局（静态）初始化区
	    p1 = (char *)malloc(10); 
	    p2 = (char *)malloc(20); 
	    分配得来得10和20字节的区域就在堆区。
	    strcpy(p1, "123456"); 123456\0放在常量区，编译器可能会将它与p3所指向的"123456"优化成一个地方。
	}



http://blog.csdn.net/sgbfblog/article/details/7772153

http://blog.163.com/xychenbaihu@yeah/blog/static/132229655201311884819764/

默认情况下，malloc函数分配内存，如果请求内存大于128K（可由M_MMAP_THRESHOLD选项调节），那就不是去推_edata指针了，而是利用mmap系统调用，从堆和栈的中间分配一块虚拟内存。

当最高地址空间的空闲内存超过128K（可由M_TRIM_THRESHOLD选项调节）时，执行内存紧缩操作（trim）。


# 3. 内存全景图

![](/kvm_blog/files/kernel/memory.gif)


1.清理Cache
/proc/sys/vm/drop_caches

--sync，将脏数据写入磁盘




# 4. 物理内存地址布局

三个内存管理区：

- ZONE_DMA：包含低于16MB的存储器页。
- ZONE_NORMAL：16MB---896MB
- ZONE_HIGHMEM：>896MB的存储器页

高端内存是指物理地址大于 896M 的内存。

对于这样的内存，无法在“内核直接映射空间”进行映射。因为“内核直接映射空间”最多只能从 3G 到 4G，只能直接映射 1G 物理内存，对于大于 1G 的物理内存，无能为力。实际上，“内核直接映射空间”也达不到 1G， 还得留点线性空间给“内核动态映射空间” 呢。因此，Linux 规定“内核直接映射空间” 最多映射 896M 物理内存。

对 于高端内存，可以通过 alloc_page() 或者其它函数获得对应的 page，但是要想访问实际物理内存，还得把 page 转为线性地址才行（为什么？想想 MMU 是如何访问物理内存的），也就是说，我们需要为高端内存对应的 page 找一个线性空间，这个过程称为高端内存映射。

高端内存映射有三种方式：

- 映射到“内核动态映射空间”  
这种方式很简单，因为通过 vmalloc() ，在”内核动态映射空间“申请内存的时候，就可能从高端内存获得页面（参看 vmalloc 的实现），因此说高端内存有可能映射到”内核动态映射空间“ 中。

- 永久内核映射  
如果是通过 alloc_page() 获得了高端内存对应的 page，如何给它找个线性空间？
内核专门为此留出一块线性空间，从 PKMAP_BASE 到 FIXADDR_START ，用于映射高端内存。在 2.4 内核上，这个地址范围是 4G-8M 到 4G-4M 之间。这个空间起叫“内核永久映射空间”或者“永久内核映射空间”

这个空间和其它空间使用同样的页目录表，对于内核来说，就是 swapper_pg_dir，对普通进程来说，通过 CR3 寄存器指向。

通常情况下，这个空间是 4M 大小，因此仅仅需要一个页表即可，内核通过来 pkmap_page_table 寻找这个页表。

通过 kmap()， 可以把一个 page 映射到这个空间来

由于这个空间是 4M 大小，最多能同时映射 1024 个 page。因此，对于不使用的的 page，及应该时从这个空间释放掉（也就是解除映射关系），通过 kunmap() ，可以把一个 page 对应的线性地址从这个空间释放出来。


- 临时映射  
内核在 FIXADDR_START 到 FIXADDR_TOP 之间保留了一些线性空间用于特殊需求。这个空间称为“固定映射空间”
在这个空间中，有一部分用于高端内存的临时映射。
这块空间具有如下特点：
	- 每个 CPU 占用一块空间
	- 在每个 CPU 占用的那块空间中，又分为多个小空间，每个小空间大小是 1 个 page，每个小空间用于一个目的，这些目的定义在 kmap_types.h 中的 km_type中。

当要进行一次临时映射的时候，需要指定映射的目的，根据映射目的，可以找到对应的小空间，然后把这个空间的地址作为映射地址。这意味着一次临时映射会导致以前的映射被覆盖。
通过 kmap_atomic() 可实现临时映射。

## 4.1 非连续区映射 ##

每个非连续内存区都对应一个类型为 vm_struct的描述符，通过next字段，这些描述符被插入到一个vmlist链表中。

三种非连续区的类型：

- VM_ALLOC   -物理内存(调用alloc_page)和线性地址同时申请，物理内存是 __GFP_HIGHMEM类型（分配顺序是HIGH, NORMAL, DMA ）（可见vmalloc不仅仅可以映射__GFP_HIGHMEM页框，它的主要目的是为了将零散的，不连续的页框拼凑成连续的内核逻辑地址空间...）
- VM_MAP     -仅申请线性区，物理内存另外申请，是VM_ALLOC的简化版
- VM_IOREMAP -仅申请线性区，物理内存另外申请（这里的物理内存一般都是高端内存，大于896M的内存）

## 4.2. 永久内核映射 ##

永久内存映射允许建立长期映射。使用主内核页表中swapper_pg_dir的一个专门页表。

- pkmap_page_table: 专门的页表。页表表项数由LAST_PKMAP(512或1024）产生。
- page_address_htable: 存放地址的
- pkmap_count: 包含LAST_PKMAP个计数器的数组。
- PKMAP_BASE: 页表线性地址从PKMAP_BASE开始。

如果LAST_PKMAP个项都用完，则把当前进程置为 TASK_UNINTERRUPTIBLE，并调用schedule()

## 4.3 临时内存映射 ##

可以用在中断处理函数和可延迟函数的内部，从不阻塞。因为临时内存映射是固定内存映射的一部分，一个地址固定给一个内核成分使用。

每个CPU都有自己的一个13个窗口（一个线性地址及页表项）的集合。

	enum km_type {
	KM_BOUNCE_READ,
	KM_SKB_SUNRPC_DATA,
	KM_SKB_DATA_SOFTIRQ,
	KM_USER0,
	KM_USER1,
	KM_BIO_SRC_IRQ,
	KM_BIO_DST_IRQ,
	KM_PTE0,
	KM_PTE1,
	KM_IRQ0,
	KM_IRQ1,
	KM_SOFTIRQ0,
	KM_SOFTIRQ1,
	KM_TYPE_NR
	};

所有固定映射的固定线性地址

	enum fixed_addresses {
	FIX_HOLE,
	FIX_VSYSCALL,
	....
	#ifdef CONFIG_HIGHMEM
	FIX_KMAP_BEGIN,    /* reserved pte's for temporary kernel mappings */
	FIX_KMAP_END = FIX_KMAP_BEGIN+(KM_TYPE_NR*NR_CPUS)-1,
	#endif
	.......
	__end_of_permanent_fixed_addresses,
	/* temporary boot-time mappings, used before ioremap() is functional */
	#define NR_FIX_BTMAPS    16
	FIX_BTMAP_END = __end_of_permanent_fixed_addresses,
	FIX_BTMAP_BEGIN = FIX_BTMAP_END + NR_FIX_BTMAPS - 1,
	FIX_WP_TEST,
	__end_of_fixed_addresses
	};

注意 fixed_addresses 的地址从上至下是倒着的，FIX_HOLE的地址等于 0xfffff000，是一个洞

	#define __fix_to_virt(x)    (FIXADDR_TOP - ((x) << PAGE_SHIFT))
	#define __FIXADDR_TOP    0xfffff000

VMALLOC_RESERVE和896M

LINUX 内核虚拟地址空间到物理地址空间一般是固定连续影射的。

假定机器内存为512M，
从 3G开始，到3G + 512M 为连续固定影射区。zone_dma, zone_normal为这个区域的。固定影射的VADDR可以直接使用（get a free page, then use pfn_to_virt()等宏定义转换得到vaddr）或用kmalloc等分配. 这样的vaddr的物理页是连续的。得到的地址也一定在固定影射区域内。

如果内存紧张，连续区域无法满足，调用vmalloc分配是必须的，因为它可以将物理不连续的空间组合后分配，所以更能满足分配要求。vmalloc可以映射高端页框，也可以映射底端页框。vmalloc的作用只是为了提供逻辑上连续的地址。。。

但 vmalloc分配的vaddr一定不能与固定影射区域的vaddr重合。因为vaddr到物理页的影射同时只能唯一。所以vmalloc得到的 vaddr要在3G + 512m 以上才可以。也就是从VMALLOC_START开始分配。 VMALLOC_START比连续固定影射区大最大vaddr地址还多8-16M（2*VMALLOC_OFFSET)--有个鬼公式在

	#define VMALLOC_OFFSET   8*1024
	#define VMALLOC_START   (high_memory - 2*VMALLOC_OFFSET) & ~(VMALLOC_OFFSET-1)

high_memory 就是固定影射区域最高处。

空开8-16M做什么？ 为了捕获越界的mm_fault.
同样，vmalloc每次得到的VADDR空间中间要留一个PAGE的空（空洞），目的和上面的空开一样。你vmalloc(100)2次，得到的2个地址中间相距8K。
如果连续分配无空洞，那么比如
p1=vmalloc(4096)；
p2=vmalloc(4096)；
如果p1使用越界到p2中了，也不会mm_falut. 那不容易debug.

下面说明VMALLOC_RESERVE和896M的问题。

上面假设机器物理512M的case. 如果机器有1G物理内存如何是好？那vmalloc()的vaddr是不是要在3G + 1G + 8M 空洞以上分配？超过寻址空间了吗。
这时，4G 下面保留的VMALLOC_RESERVE 128m 就派上用场了。
也就是说如果物理内存超过896M, high_memory也只能在3G + 896地方。可寻址空间最高处要保留VMALLOC_RESREVE 128M给vmalloc用。

所以这128M的VADDR空间是为了vmalloc在物理超过了896M时候使用。如果物理仅仅有512M, 一般使用不到。因为VMALLOC_START很低了。如果vmalloc太多了才会用到。

high_memory在arch/i386/kernel, mm的初始化中设置。根据物理内存大小和VMALLOC_RESERVE得到数值.

所以说那128M的内核线性地址仅仅是为了影射1G以上的物理内存的不对的。如果物理内存2G,1G以下的vmalloc也用那空间影射。总之，内核的高端线性地址是为了访问内核固定映射以外的内存资源

看vmalloc分配的东西可以用

	show_vmalloc()
	{
		struct vm_struct **p, *tmp;
		
		for(p = &vmlist; (tmp = *p); p = &tmp->next) {
		printk("%p %p %d\n", tmp, tmp->addr, tmp->size
		
		}
	}

用户空间当然可以使用高端内存，而且是正常的使用，内核在分配那些不经常使用的内存时，都用高端内存空间（如果有），所谓不经常使用是相对来说的，比如内核的一些数据结构就属于经常使用的，而用户的一些数据就属于不经常使用的。

用户在启动一个应用程序时，是需要内存的，而每个应用程序都有3G的线性地址，给这些地址映射页表时就可以直接使用高端内存。

而且还要纠正一点的是：那128M线性地址不仅仅是用在这些地方的，如果你要加载一个设备，而这个设备需要映射其内存到内核中，它也需要使用这段线性地址空间来完成，否则内核就不能访问设备上的内存空间了。

总之，内核的高端线性地址是为了访问内核固定映射以外的内存资源

实际上高端内存是针对内核一段特殊的线性空间提出的概念，和实际的物理内存是两码事。进程在使用内存时，触发缺页异常，具体将哪些物理页映射给用户进程是内核考虑的事情。在用户空间中没有高端内存这个概念。

## 4.4 X86 架构下的物理内存 ##
http://blog.csdn.net/dog250/article/details/6243276
http://www.kerneltravel.net/journal/v/mem.htm
其它体系结构我没有深入研究过，然而对于x86而言，我们很多人都是很了解的。其内存可以支持4G(不考虑PAE)，因为地址总线为32位，也就是说32条1位的线缆可以选择4G的地址，因此我们想当然的认为我们买了两条2G的内存插入以后，我们的系统就可以有4G的内存可用了，我们的系统内存在满载运行，然而果真如此吗？答案是否定的！
     
因为所谓的地址总线32位是指从cpu引脚出来的总线是32位，是针对于cpu而言的，具体这些总线最终能全部连接在主板的ram上吗？会不会还会连接到其它的设备上呢？这要看主板怎么设计了。这里主板上的北桥芯片解除了cpu和设备之间的地址偶合，典型的设计为cpu出来的地址总线32位全部连接在北桥芯片之上，当cpu发出一个32位的地址比如0xcb000000的时候，由北桥来决定该地址发往何处，可能发往内存ram，也可能发往显示卡，也可能发往其它的二级总线，当然也可能发往南桥芯片(一个类似的解析地址的芯片，北桥解耦了cpu和主板芯片/总线，而南桥则解耦了主板芯片/总线和外部设备，比如ata硬盘，usb之类的设备就可以连接在南桥芯片上)。如果北桥选择将该地址发往PCI总线上，那么显然内存ram就收不到这个地址请求，而且自从主板设计好了之后，理论上该地址就永远被发送给了PCI，当然了，你可以通过诸如跳线之类的办法来更改之，(而且现在很多板子都有被bios“自动探测/识别/设置”的功能，此种情形下地址拓扑信息就不必记录在bios里面了，而是在bios开始运行的时候自动生成，生成的方式不外乎侦测-往特定针脚发送电平序列信号，然后得到回复，不过具体往哪里发送电平信息也必须由主板和cpu来确定标准)，因此虽然你有4G的所谓的满载的ram，然而它的地址0xcb000000却不能被使用。以上仅仅是一个例子，主板上还有很多的设备或者总线会占据一些地址总线上的地址，这样说来你的4G的ram会有很多不能使用，典型的，intel提出了PAE，即物理地址扩展，使得可以支持4G以上的ram，实际上它的实现很简单，就是为ram增加几个地址总线位，变成36位的地址总线，这样就可以插入64G的ram了，这时4G以上的地址总线空间将不会被其它设备占据，而北桥只会将地址发往ram。
     
既然4G的地址空间不能完全由ram内存条使用，那么ram不能使用哪些地址呢？这个信息很重要，因为这个信息会指导操作系统内核进行物理内存分配，比如其它地址使用的地址处的页面就不能被分配，否则就访问到设备了，因此这些个地址处的页面应该设置为保留，永远不能被使用，事实上，它们被浪费了。这些地址信息存放的位置是BIOS，BIOS里面存放着很重要的信息，这些信息可以组成一张逻辑拓扑图，真实反映主板上的芯片是如何排列放置的，待到主板上电后，主板上的芯片和总线就形成了一张真实的“地图”，在bios拓扑图的指导下被检测。
     
既然BIOS里面存放拓扑图，那么操作系统内核在启动的时候怎样得到它呢，得到了它之后，操作系统才能建立自己的物理地址空间映射。得到bios信息的办法莫多于bios调用了，也就是0x15调用，参数由寄存器指定，如果你想得到地址信息，也就是那张拓扑图，那么你要将eax设置成0X0000E820，然后读取返回即可，以下是linux在拥有256M内存的机器上得到的地址信息，该信息在内核启动的时候通过bios调用得到：

	BIOS-provided physical RAM map:
	BIOS-e820: 0000000000000000 - 000000000009f800 (usable)
	BIOS-e820: 000000000009f800 - 00000000000a0000 (reserved)
	BIOS-e820: 00000000000dc000 - 00000000000e0000 (reserved)
	BIOS-e820: 00000000000e4000 - 0000000000100000 (reserved)
	BIOS-e820: 0000000000100000 - 000000000fef0000 (usable)
	BIOS-e820: 000000000fef0000 - 000000000feff000 (ACPI data)
	BIOS-e820: 000000000feff000 - 000000000ff00000 (ACPI NVS)
	BIOS-e820: 000000000ff00000 - 0000000010000000 (usable)
	BIOS-e820: 00000000fec00000 - 00000000fec10000 (reserved)
	BIOS-e820: 00000000fee00000 - 00000000fee01000 (reserved)
	BIOS-e820: 00000000fffe0000 - 0000000100000000 (reserved)

显然所有的ram都可以使用，毕竟它太小了。下面是一个拥有4G内存的机器的地址信息：

	BIOS-provided physical RAM map:
	BIOS-e820: 0000000000000000 - 000000000009f000 (usable)
	BIOS-e820: 000000000009f000 - 00000000000a0000 (reserved)
	BIOS-e820: 00000000000f0000 - 0000000000100000 (reserved)
	BIOS-e820: 0000000000100000 - 00000000bdc90000 (usable)
	BIOS-e820: 00000000bdc90000 - 00000000bdce3000 (ACPI NVS)
	BIOS-e820: 00000000bdce3000 - 00000000bdcf0000 (ACPI data)
	BIOS-e820: 00000000bdcf0000 - 00000000bdd00000 (reserved)
	BIOS-e820: 00000000e0000000 - 00000000f0000000 (reserved)
	BIOS-e820: 00000000fec00000 - 0000000100000000 (reserved)
	BIOS-e820: 0000000100000000 - 0000000140000000 (usable)

可见0000000000100000 - 00000000bdc90000总共3G左右的ram是可以被OS使用的，它们是可以被寻址的，而其它的将近1G的ram被设置为reserved，它们被浪费了。在linux的/proc/meminfo中MemTotal:一行所显示的就是0x00000000bdc90000和0000000000100000的差，具体这些地址被用于什么设备，从/proc/iomem中可以看到，以下是256M内存机器的iomem：

	00000000-0000ffff : reserved
	00010000-0009f7ff : System RAM
	0009f800-0009ffff : reserved
	000a0000-000bffff : Video RAM area
	000c0000-000c7fff : Video ROM
	000c8000-000c8fff : Adapter ROM
	000c9000-000c9fff : Adapter ROM
	000ca000-000cafff : Adapter ROM
	000dc000-000dffff : reserved
	000e4000-000fffff : reserved
	000f0000-000fffff : System ROM
	00100000-0feeffff : System RAM
	01000000-01242d96 : Kernel code
	01242d97-0133c847 : Kernel data
	01394000-013cc243 : Kernel bss
	0fef0000-0fefefff : ACPI Tables
	0feff000-0fefffff : ACPI Non-volatile Storage
	0ff00000-0fffffff : System RAM
	10000000-1000ffff : 0000:00:11.0
	10010000-1001ffff : 0000:00:12.0
	10020000-1002ffff : 0000:00:13.0
	10030000-10037fff : 0000:00:0f.0
	10038000-1003bfff : 0000:00:10.0
	e8000000-e87fffff : 0000:00:0f.0
	e8800000-e8800fff : 0000:00:10.0
	f0000000-f7ffffff : 0000:00:0f.0
	fec00000-fec0ffff : reserved
	  fec00000-fec00fff : IOAPIC 0
	fee00000-fee00fff : Local APIC
	  fee00000-fee00fff : reserved
	fffe0000-ffffffff : reserved   //这里一般是bios，凡是cpu发出的到这些地址的访问，全部被路由到bios

再次重申一遍，是4G以下的某些地址预留给了设备而不是4G以下的ram预留给了设备，很多设备是不使用ram芯片作存储的，它们只是占用了一些地址而已。比如上述iomem的内容中000c8000-000c8fff : Adapter ROM就是将前面的地址预留给了ROM芯片，cpu发出对该地址段中的一个的访问时，芯片组会将地址总线信号发往ROM而不是内存ram。
     
在linux中，内核启动的时候，在很早的阶段，内核调用detect_memory来通过bios探测内存，它又调用detect_memory_e820来探测地址信息：

	static int detect_memory_e820(void)
	{
	    int count = 0;
	    struct biosregs ireg, oreg;
	    struct e820entry *desc = boot_params.e820_map;
	    static struct e820entry buf; /* static so it is zeroed */
	    initregs(&ireg);
	    ireg.ax  = 0xe820;
	    ireg.cx  = sizeof buf;
	    ireg.edx = SMAP;
	    ireg.di  = (size_t)&buf;
	    do {
	        intcall(0x15, &ireg, &oreg); //调用bios中断
	        ireg.ebx = oreg.ebx; 
	        if (oreg.eflags & X86_EFLAGS_CF)
	            break;
	        if (oreg.eax != SMAP) {
	            count = 0;
	            break;
	        }
	        *desc++ = buf;
	        count++;
	    } while (ireg.ebx && count < ARRAY_SIZE(boot_params.e820_map));
	    return boot_params.e820_entries = count;
	}

这个函数调用完毕之后，boot_params.e820_map中就保存了“哪段地址是干什么用”的信息，将来linux在初始化物理内存的时候将使用这个信息，比如将保留给设备的地址处的页面设置为reversed，这样在分配物理页面的时候，会绕过这些被保留的地址处的页面。
附：察看linux中的内存的问题在linux中可以通过top，free，/proc/meminfo等多种方式查看系统的内存，然而不同的内核编译选项编译出来的内核显示出来的内存总量却是不同的，在编译了HIGHMEM64G，也就是打开了PAE的情况下编译的内核，查到的内存总量会包括预留地址处的内存页面，而不打开PAE则不计算这些页面，显然打开PAE时的计算方式是不合理的，毕竟既然有那么多内存就应该可被使用，而实际上那些页面是不能使用的。

附：x86体系的地址映射图(注意，是地址，而不是ram)
 
![](/kvm_blog/files/kernel/address_map.gif)

# 5.内存碎片分析#
前言，本案例分析s2lm遇到的CPU飙升问题，深入研究Linux的内存回收、分配机制、分析内存碎片和CPU飙升原因。并提出将SD卡录像使用的cache从系统的cache中抽取出来进行管理的方案来解决内存碎片问题.

## 5.1 问题分析 ##
查看top:

- 对比发现，cache突然减少，正常情况下cache比较多（包含磁盘文件缓存，如sd卡录像文件的缓存；文件映射缓存，如代码段；匿名映射缓存，如堆和栈；slab分配器高速缓存（dentry和inode））。
- cpu的sys使用变大。
- perf分析：lzma_main 可见在频繁读取flash.

## 5.2 内存分配机制 ##
    
Linux为了解决内存碎片问题，使用了伙伴算法来管理内存。所有的内存分配函数只有一个入口函数，就是 __alloc_pages_nodemask，来看下它的执行流程：

	1__alloc_pages_nodemask
	2  -> get_page_from_freelist
	3	 N-> wake_all_kswapd
	4       -> __perform_reclaim
	5         -> get_page_from_freelist
    6           N-> should_oom
	7              N-> shoud_alloc_retry
    8                 N-> warn_alloc_failed
	9              Y-> oom
    10          Y-> success
	11   Y-> success 


	1 get_page_from_freelist
	2   -> zone_writemark_ok
	3     Y-> buffered_rmqueue 
	4       -> success
	5     N-> fail

从代码看，zone_watermark_ok 除了检查申请后的 free 页面个数是否在水线以下，还会检查申请后的各个 order的 free的比例情况，也就是红框区域的代码。举个例子，如果目前

free=2256 pages
mark=489
order=3
free_area[0]=1107  =1107   =1107 pages
free_area[1]=300   =300*2  =600 pages
free_area[2]=123   =123*4  =492 pages
free_area[3]=7     =7*8    =56 pages

这种情况下申请完一个 order 为3的页面后 order>=1的页面个数为 2256-8-1107=1141 > 489/2，order>=2的页面个数为 1141-600=541>489/4，order>=3的页面个数为 541-492=49<489/8，此时认为在申请完 order 为 3的内存块后，order >=3 的内存块的比例偏小，需要回收内存来平衡。

我们怀疑是内存碎片，查看碎片情况，虽然 free 内存还很多，但是 order=2以上的内存块已经没有了，碎片的情况已经比较严重了

cat /proc/buddyinfo
Node 0, zone Normal 931 1337 11 0 0 0 0 0 0 0 0

原因应该是内存碎片引起内存区域不平衡，从而需要通过回收内存去平衡，当碎片化严重时，可能会导致代码段被回收，当代码段被锁住后，也就没有能够再可以回收的内存了，从而导致内存申请失败，此时需要一直尝试回收并重新申请，从而引起 CPU 上升。

## 5.3 内存碎片研究 ##

先来看下内存碎片是怎么产生的。Linux内存碎片分为两种，一种是内存碎片，是指那种内存申请出去了，当实际没有使用到的情况。比如你申请了 106个字节，系统会实际分给你 128 个字节，这相差的 22 字节就属于內部碎片。另外一种是外部碎片，是指那种内存没有分配出去，但是实际上可能分配不出去的情况。比如以下情况：

	---------------------------------------------
	| 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 |
	---------------------------------------------

虽然 free 有 9个 pages，但是已经无法满足连续 4 个 page的需求了，如果这些申请出去的内存可以回收，那还是能够满足需求的，如果这些申请出去的内存不可回收，那么将会永远申请不到连续4个 page 的内存。

上面讲到了要解决内存碎片问题，可以从 cache 入手，我的想法是如果把 sd 卡录像使用的 cache 从系统 cache 中分离出来，进行预分配，并且由自己进行甘利，就如前面所讲的，把不能回收的和能够回收的内存分开管理。

![](/kvm_blog/files/kernel/cache_pool.png)

设计思路，如上图所示：
创建一个内存池，写 sd 卡时从池中申请页面用于 cache，当池中的页面个数小于一半时，释放 cache还回池中，但不还给操作系统。

只要能够找到申请和释放 cache 的人口就能够实现以上方案，因此必须搞清楚 sd 卡读写过程

read/write
------------
vfs
------------
fat 文件系统
------------
映射层
------------
提交IO操作，生成请求，插入到磁盘的请求队列中
------------

cache结构:grab_cache_page_write_begin->__page_cache_alloc

总结：Cache虽然可以提高硬盘读者的性能，但是确实会存在引起内存碎片问题，因为cache申请的内存分散开导致没有整片的内存！

# 参考资料 #

反向映射  
www.cnblogs.com/zhaoyl/p/3695517.html  
www.tuicool.com/articles/JRJjQji

页面回收及反射机制  
http://os.51cto.com/art/201103/249879_3.htm

slab 分配器  
http://blog.csdn.net/vanbreaker/article/details/7671618

http://www.ilinuxkernel.com/files/Linux_Physical_Memory_Page_Allocation.pdf