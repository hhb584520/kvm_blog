# 内存虚拟化
内存虚拟化的目的有如下两个。
- 提供给虚拟机一个从零地址开始的连续物理内存空间。
- 在各虚拟机之间有效隔离、调度以及共享内存资源

[kvm-overview.pdf](/kvm_blog/files/virt_mem/kvm-overview.pdf)

## 1. 概述
为了让客户机操作系统使用一个隔离的、从零开始且具有连续性的内存空间，VMM引入一层新的地址空间，即客户机物理地址空间。客户机物理地址空间是客户机操作系统所能“看见”和管理的物理地址空间，这个地址空间不是真正的物理地址空间，它和物理地址空间还有一层映射。有了客户机物理地址空间，就形成了从应用程序所在的客户机虚拟地址到客户机物理地址，再从客户机物理地址到宿主机物理地址的两层地址转换。前一个转换由客户机操作系统完成，后一个转换由 VMM 负责。

由于客户机物理地址不能直接用于宿主机物理 MMU 进行寻址，所以需要把客户机物理地址转换成宿主机虚拟地址 (Host Virtual Address, HVA)，为此，KVM 用一个 kvm_memory_slot 数据结构来记录每一个地址区间的映射关系，此数据结构包含了对应此映射区间的起始客户机页帧号 (Guest Frame Number, GFN)，映射的内存页数目以及起始宿主机虚拟地址。于是 KVM 就可以实现对客户机物理地址到宿主机虚拟地址之间的转换，也即首先根据客户机物理地址找到对应的映射区间，然后根据此客户机物理地址在此映射区间的偏移量 就可以得到其对应的宿主机虚拟地址。进而再通过宿主机的页表也可实现客户机物理地址到宿主机物理地址之间的转换，也即 GPA 到 HPA 的转换。

实现内存虚拟化，最主要的是实现客户机虚拟地址 (Guest Virtual Address, GVA) 到宿主机物理地址之间的转换。根据上述客户机物理地址到宿主机物理地址之间的转换以及客户机页表，即可实现客户机虚拟地址空间到客户机物理地址空间之间的 映射，也即 GVA 到 HPA 的转换。显然通过这种映射方式，客户机的每次内存访问都需要 KVM 介入，并由软件进行多次地址转换，其效率是非常低的。因此，为了提高 GVA 到 HPA 转换的效率，KVM 提供了两种实现方式来进行客户机虚拟地址到宿主机物理地址之间的直接转换。

- 其一是基于纯软件的实现方式，也即通过影子页表 (Shadow Page Table) 来实现客户虚拟地址到宿主机物理地址之间的直接转换。
- 其二是基于硬件对虚拟化(EPT)的支持，来实现两者之间的转换。下面就详细阐述两种方法在 KVM 上的具体实现。

### 1.1 四种地址

- GVA - Guest虚拟地址
- GPA - Guest物理地址
- HVA - Host 虚拟地址
- HPA - Host 物理地址

### 1.2 四种地址的转换关系

GVA->GPA
Guest OS维护的页表进行传统的操作

GPA->HVA
KVM的虚拟机实际上运行在Qemu的进程上下文中。于是，虚拟机的物理内存实际上是Qemu进程的虚拟地址。Kvm要把虚拟机的物理内存分成几个slot。这是因为，对计算机系统来说，物理地址是不连续的，除了bios和显存要编入内存地址，设备的内存也可能映射到内存了，所以内存实际上是分为一段段的。

![](/kvm_blog/files/virt_mem/gpatohva.png)

### 1.3 QEMU 中物理内存的注册

	kvm_set_phys_mem()->
	kvm_set_user_memory_region()->
	kvm_vm_ioctl() 进入kernel->
	KVM_SET_USER_MEMORY_REGION->
	kvm_vm_ioctl_set_memory_region()->
	__kvm_set_memory_region()

**重要数据结构**

QEMU对guest物理内存分段的的描述：

	typedef struct KVMSlot
	{
	     hwaddr start_addr;               Guest物理地址块的起始地址
	     ram_addr_t memory_size;          大小
	     void *ram;                       QUMU用户空间地址 
	     int slot;                        slot id
	     int flags;
	} KVMSlot;

指定了vm的物理地址，同时指定了Qemu分配的用户地址，前面一个地址是GPA，后
面一个地址是HVA。可见，一个memslot就是建立了GPA到HVA的映射关系。

**内核态描述结构：**

	struct kvm_memslots {
		int nmemslots;                      slot number
		struct kvm_memory_slot memslots[KVM_MEMORY_SLOTS + KVM_PRIVATE_MEM_SLOTS];
	};
	
	struct kvm_memory_slot {
		gfn_t base_gfn;                     该块物理内存块所在guest 物理页帧号
		unsigned long npages;               该块物理内存块占用的page数
		unsigned long flags;
		unsigned long *rmap;                分配该块物理内存对应的host内核虚拟地址（vmalloc分配）
		unsigned long *dirty_bitmap;
		struct {
			unsigned long rmap_pde;
			int write_count;
		} *lpage_info[KVM_NR_PAGE_SIZES - 1];
		unsigned long userspace_addr;       用户空间地址（QEMU)
		int user_alloc;
	};
	
**guest物理页框到HVA转换**
	
	hva=base_hva+(gfn-base_gfn)*PAGE_SIZE
	
	unsigned long gfn_to_hva(struct kvm *kvm, gfn_t gfn)
	{
	 struct kvm_memory_slot *slot;
	 gfn = unalias_gfn_instantiation(kvm, gfn);
	 slot = gfn_to_memslot_unaliased(kvm, gfn);
	 if (!slot || slot->flags & KVM_MEMSLOT_INVALID)
	    return bad_hva();
	 return (slot->userspace_addr + (gfn - slot->base_gfn) * PAGE_SIZE);
	}


## 2. 影子页表
由 于宿主机 MMU 不能直接装载客户机的页表来进行内存访问，所以当客户机访问宿主机物理内存时，需要经过多次地址转换。也即首先根据客户机页表把客户机虚拟地址转传成客户机物理地址，然后再通过客户机物理地址到宿主机虚拟地址之间的映射转换成宿主机虚拟地址，最后再根据宿主机页表把宿主机虚拟地址转换成宿主机物理地址。而 通过影子页表，则可以实现客户机虚拟地址到宿主机物理地址的直接转换。

为了快速检索客户机页表所对应的的影子页表，KVM 为每个客户机都维护了一个哈希表，影子页表和客户机页表通过此哈希表进行映射。对于每一个客户机来说，客户机的页目录和页表都有唯一的客户机物理地址，通过页目录 / 页表的客户机物理地址就可以在哈希链表中快速地找到对应的影子页目录 / 页表。在检索哈希表时，KVM 把客户机页目录 / 页表的客户机物理地址低 10 位作为键值进行索引，根据其键值定位到对应的链表，然后遍历此链表找到对应的影子页目录 / 页表。当然，如果不能发现对应的影子页目录 / 页表，说明 KVM 还没有为其建立，于是 KVM 就为其分配新的物理页并加入此链表，从而建立起客户机页目录 / 页表和对应的影子页目录 / 页表之间的映射。当客户机切换进程时，客户机操作系统会把待切换进程的页表基址载入 CR3，而 KVM 将会截获这一特权指令，进行新的处理，也即在哈希表中找到与此页表基址对应的影子页表基址，载入客户机 CR3，使客户机在恢复运行时 CR3 实际指向的是新切换进程对应的影子页表。

影子页表异常处理机制

在通过影子页表进行寻址的过程中，有两种原因会引起影子页表的 缺页异常，一种是由客户机本身所引起的缺页异常，具体来说就是客户机所访问的客户机页表项存在位 (Present Bit) 为 0，或者写一个只读的客户机物理页，再者所访问的客户机虚拟地址无效等。另一种异常是由客户机页表和影子页表不一致引起的异常。

当缺页异常 发生时，KVM 首先截获该异常，然后对发生异常的客户机虚拟地址在客户机页表中所对应页表项的访问权限进行检查，并根据引起异常的错误码，确定出此异常的原因，进行相应 的处理。如果该异常是由客户机本身引起的，KVM 则直接把该异常交由客户机的缺页异常处理机制来进行处理。如果该异常是由客户机页表和影子页表不一致引起的，KVM 则根据客户机页表同步影子页表。为此，KVM 要建立起相应的影子页表数据结构，填充宿主机物理地址到影子页表的页表项，还要根据客户机页表项的访问权限修改影子页表对应页表项的访问权限。

由 于影子页表可被载入物理 MMU 为客户机直接寻址使用， 所以客户机的大多数内存访问都可以在没有 KVM 介入的情况下正常执行，没有额外的地址转换开销，也就大大提高了客户机运行的效率。但是影子页表的引入也意味着 KVM 需要为每个客户机的每个进程的页表都要维护一套相应的影子页表，这会带来较大内存上的额外开销，此外，客户机页表和和影子页表的同步也比较复杂。因 此，Intel 的 EPT(Extent Page Table) 技术和 AMD 的 NPT(Nest Page Table) 技术都对内存虚拟化提供了硬件支持。这两种技术原理类似，都是在硬件层面上实现客户机虚拟地址到宿主机物理地址之间的转换。下面就以 EPT 为例分析一下 KVM 基于硬件辅助的内存虚拟化实现。

Guest OS所维护的页表负责传统的从guest虚拟地址GVA到guest物理地址GPA的转换。如果MMU直接装载guest OS所维护的页表来进行内存访问，那么由于页表中每项所记录的都是GPA，MMU无法实现地址翻译。

解决方案：影子页表 (Shadow Page Table)
作用：GVA直接到HPA的地址翻译,真正被VMM载入到物理MMU中的页表是影子页表；

![](/kvm_blog/files/virt_mem/spt1.png)

### 2.1 影子映射关系

SPD是PD的影子页表，SPT1/SPT2是PT1/PT2的影子页表。由于客户PDE和PTE给出的页表基址和页基址并不是真正的物理地址，所以我们采用虚线表示PDE到GUEST页表以及PTE到普通GUEST页的映射关系。

![](/kvm_blog/files/virt_mem/spts.png)

### 2.2 影子页表的建立

- 开始时，VMM中的与guest OS所拥有的页表相对应的影子页表是空的；
- 而影子页表又是载入到CR3中真正为物理MMU所利用进行寻址的页表，因此开始时任何的内存访问操作都会引起缺页异常；导致vm发生VM Exit；进入handle_exception();


		if (is_page_fault(intr_info)) {
			/* EPT won't cause page fault directly */
			BUG_ON(enable_ept);
			cr2 = vmcs_readl(EXIT_QUALIFICATION);
			trace_kvm_page_fault(cr2, error_code);
		
			if (kvm_event_needs_reinjection(vcpu))
				kvm_mmu_unprotect_page_virt(vcpu, cr2);
			return kvm_mmu_page_fault(vcpu, cr2, error_code, NULL, 0);
		}


获得缺页异常发生时的CR2,及当时访问的虚拟地址；

	进入kvm_mmu_page_fault()(vmx.c)->
	r = vcpu->arch.mmu.page_fault(vcpu, cr2, error_code);(mmu.c)->
	FNAME(page_fault)(struct kvm_vcpu *vcpu, gva_t addr, u32 error_code)(paging_tmpl.h)->
	FNAME(walk_addr)() 查guest页表，物理地址是否存在， 这时肯定是不存在的
	The page is not mapped by the guest. Let the guest handle it.
	inject_page_fault()->kvm_inject_page_fault() 异常注入流程；

- Guest OS修改从GVA->GPA的映射关系填入页表；
- 继续访问，由于影子页表仍是空，再次发生缺页异常；
- FNAME(page_fault)->
- FNAME(walk_addr)() 查guest页表，物理地址映射均是存在->
- FNAME(fetch):
遍历影子页表，完成创建影子页表（填充影子页表）;
在填充过程中，将客户机页目录结构页对应影子页表页表项标记为写保护，目的截获对于页目录的修改（页目录也是内存页的一部分，在页表中也是有映射的，guest对页目录有写权限，那么在影子页表的页目录也是可写的，这样对页目录的修改导致VMM失去截获的机会）

### 2.3 影子页表的填充

	shadow_page = kvm_mmu_get_page(vcpu, table_gfn, addr, level-1, direct, access, sptep);
	index = kvm_page_table_hashfn(gfn);
	hlist_for_each_entry_safe
	if (sp->gfn == gfn)
	{……}
	else
	{sp = kvm_mmu_alloc_page(vcpu, parent_pte);}

为了快速检索GUEST页表所对应的的影子页表，KVM 为每个GUEST都维护了一个哈希
表，影子页表和GUEST页表通过此哈希表进行映射。对于每一个GUEST来说，GUEST
的页目录和页表都有唯一的GUEST物理地址，通过页目录/页表的客户机物理地址就
可以在哈希链表中快速地找到对应的影子页目录/页表。

### 2.4 影子页表的缓存

Guest OS修改从GVA->GPA的映射关系，为保证一致性，VMM必须对影子页表也做相应的维护，这样，VMM必须截获这样的内存访问操作；
导致VM Exit的机会
INVLPG
MOV TO CR3
TASK SWITCH（发生MOV TO CR3 ）
以INVLPG触发VM Exit为例：
static void FNAME(invlpg)(struct kvm_vcpu *vcpu, gva_t gva)
Paging_tmpl.h
影子页表项的内容无效
GUEST在切换CR3时，VMM需要清空整个TLB，使所有影子页表的内容无效。在多进程GUEST操作系统中，CR3将被频繁地切换，某些影子页表的内容可能很快就会被再次用到，而重建影子页表是一项十分耗时的工作，这里需要缓存影子页表，即GUEST切换CR3时不清空影子页表。
影子页表方案总结

内存虚拟化的两次转换：
GVA->GPA (GUEST的页表实现)
GPA->HPA (VMM进行转换)

影子页表将两次转换合一
根据GVA->GPA->HPA 计算出GVA->HPA,填入影子页表

优点：
由于影子页表可被载入物理 MMU 为客户机直接寻址使用，所以客户机的大多数内存访问都可以在没有 KVM 介入的情况下正常执行，没有额外的地址转换开销，也就大大提高了客户机运行的效率。

缺点：
1、KVM 需要为每个客户机的每个进程的页表都要维护一套相应的影子页表，这会带来较大内存上的额外开销;
2、客户在读写CR3、执行INVLPG指令或客户页表不完整等情况下均会导致VM exit，这导致了内存虚拟化效率很低
3、客户机页表和和影子页表的同步也比较复杂。

因此，Intel 的 EPT(Extent Page Table) 技术和 AMD 的 NPT(Nest Page Table) 技术都对内存虚拟化提供了硬件支持。这两种技术原理类似，都是在硬件层面上实现客户机虚拟地址到宿主机物理地址之间的转换。

## 3. EPT 页表
硬件辅助方案EPT（Extended Page Table）技术在原有客户机页表对客户机虚拟地址到客户机物理地址映射的基础上，又引入了 EPT 页表来实现客户机物理地址到宿主机物理地址的另一次映射，这两次地址映射都是由硬件自动完成。客户机运行时，客户机页表被载入 CR3，而 EPT 页表被载入专门的 EPT 页表指针寄存器 EPTP。EPT 页表对地址的映射机理与客户机页表对地址的映射机理相同。

在 客户机物理地址到宿主机物理地址转换的过程中，由于缺页、写权限不足等原因也会导致客户机退出，产生 EPT 异常。对于 EPT 缺页异常，KVM 首先根据引起异常的客户机物理地址，映射到对应的宿主机虚拟地址，然后为此虚拟地址分配新的物理页，最后 KVM 再更新 EPT 页表，建立起引起异常的客户机物理地址到宿主机物理地址之间的映射。对 EPT 写权限引起的异常，KVM 则通过更新相应的 EPT 页表来解决。

由此可以看出，EPT 页表相对于前述的影子页表，其实现方式大大简化。而且，由于客户机内部的缺页异常也不会致使客户机退出，因此提高了客户机运行的性能。此外，KVM 只需为每个客户机维护一套 EPT 页表，也大大减少了内存的额外开销。很少 VM-Exit，客户机的 Page Fault 、INVLPG(使TLB项目失效)指令、CR3寄存器的访问等都不会引起 VM-Exit

VT-x提供了Extended Page Table(EPT)技术
硬件上直接支持GVA->GPA->HPA的两次地址转换
原理：CR3 将客户机程序所见的客户机虚拟地址（GVA）转化为客户机物理地址（GPA），然后再通过 EPT 将客户机物理地址（GPA）转化为宿主机物理地址（HPA）。这两次地址转换都是由硬件来完成，其转换效率非常高。

![](/kvm_blog/files/virt_mem/mmu_ept.png)

VPID（虚拟处理器标识），是在硬件上对 TLB 资源管理的优化，通过在硬件上为每个 TLB 项增加一个标识，用于不同的虚拟处理器的地址空间，从而能够区分开 Hypervisor 和不同处理器的 TLB。在VM-Exit是可以不让 TLB全部失效；提高了VM切换的效率。

默认已经支持，我们也可以用如下命令查看：

    [root@skl-sp2 ~]# cat /sys/module/kvm_intel/parameters/ept
    Y
    [root@skl-sp2 ~]# cat /sys/module/kvm_intel/parameters/vpid
    Y


### 3.1 二维地址翻译结构

Guest维护自身的客户页表:GVA->GPA
EPT维护GPA->HPA的映射

### 3.2 流程

- 处于非根模式的CPU加载guest进程的gCR3;
- gCR3是GPA,cpu需要通过查询EPT页表来实现GPA->HPA；
- 如果没有，CPU触发EPT Violation,由VMM截获处理；
- 假设客户机有m级页表，宿主机EPT有n级，在TLB均miss的最坏情况下，会产生m*n次内存访问，完成一次客户机的地址翻译；

![](/kvm_blog/files/virt_mem/mmu_ept1.png)

### 3.3 EPT页表的建立流程

- 初始情况下：Guest CR3指向的Guest物理页面为空页面；
- Guest页表缺页异常，KVM采用不处理Guest页表缺页的机制，不会导致VM Exit，由Guest的缺页异常处理函数负责分配一个Guest物理页面（GPA），将该页面物理地址回填，建立Guest页表结构；
- 完成该映射的过程需要将GPA翻译到HPA，此时该进程相应的EPT页表为空，产生EPT_VIOLATION，虚拟机退出到根模式下执行，由KVM捕获该异常，建立该GPA到HOST物理地址HPA的映射，完成一套EPT页表的建立，中断返回，切换到非根模式继续运行。
- VCPU的mmu查询下一级Guest页表，根据GVA的偏移产生一条新的GPA，Guest寻址该GPA对应页面，产生Guest缺页，不发生VM_Exit，由Guest系统的缺页处理函数捕获该异常，从Guest物理内存中选择一个空闲页，将该Guest物理地址GPA回填给Guest页表；
- 此时该GPA对应的EPT页表项不存在，发生EPT_VIOLATION，切换到根模式下，由KVM负责建立该GPA->HPA映射，再切换回非根模式；
- 如此往复，直到非根模式下GVA最后的偏移建立最后一级Guest页表，分配GPA，缺页异常退出到根模式建立最后一套EPT页表。
- 至此，一条GVA对应在真实物理内存单元中的内容，便可通过这一套二维页表结构获得。


### 3.4 硬件支持

- VMCS的“VMCS-Execution”:Enable EPT字段，置位后EPT功能使能，CPU会使用EPT功能进行两次转换；
- EPT页表的基地址是VMCS的“VMCS-Execution”：Extended page table pointer字段；

**Code**

	vcpu_enter_guest()->
	kvm_mmu_reload()->
	kvm_mmu_load()->
	vmx_set_cr3()
	
	
	static void vmx_set_cr3(struct kvm_vcpu *vcpu, unsigned long cr3)
	{
		unsigned long guest_cr3;
		u64 eptp;
	
		guest_cr3 = cr3;
		if (enable_ept) {
			eptp = construct_eptp(cr3);
			vmcs_write64(EPT_POINTER, eptp);
			if (is_paging(vcpu) || is_guest_mode(vcpu))
				guest_cr3 = kvm_read_cr3(vcpu);
			else
				guest_cr3 = vcpu->kvm->arch.ept_identity_map_addr;
			ept_load_pdptrs(vcpu);
		}
	
		vmx_flush_tlb(vcpu);
		vmcs_writel(GUEST_CR3, guest_cr3);
	}

vmx_handle_exit()->
	[EXIT_REASON_EPT_VIOLATION] = handle_ept_violation;
Handle_ept_violation()->
kvm_mmu_page_fault()->
tdp_page_fault()->
gfn_to_pfn(); GPA到HPA的转化分两步完成，分别通过gfn_to_hva、hva_to_pfn两个函数完成
__direct_map(); 建立EPT页表结构
Guest运行过程中，首先获得gCR3的客户页帧号(右移PAGE_SIZE)，根据其所在memslot区域获得其对应的HVA，再由HVA转化为HPA，得到宿主页帧号。若GPA->HPA的映射不存在，将会触发VM-Exit，KVM负责捕捉该异常，并交由KVM的缺页中断机制进行相应的缺页处理。kvm_vmx_exit_handlers函数数组中，保存着全部VM-Exit的处理函数，它由kvm_x86_ops的vmx_handle_exit负责调用。缺页异常的中断号为EXIT_REASON_EPT_VIOLATION，对应由handle_ept_violation函数进行处理。
tdp_page_fault是EPT的缺页处理函数,负责完成GPA->HPA转化.而传给tdp_page_fault的GPA是通过vmcs_read64函数(VMREAD指令)获得的.
gpa = vmcs_read64(GUEST_PHYSICAL_ADDRESS);


## 4. 参考资料
https://www.ibm.com/developerworks/community/blogs/5144904d-5d75-45ed-9d2b-cf1754ee936a/entry/kvm-mem?lang=en

非常不错一篇代码解读文章
http://royluo.org/2016/03/13/kvm-mmu-virtualization/

http://blog.chinaunix.net/uid-26163398-id-5674852.html