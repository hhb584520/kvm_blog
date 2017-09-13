## 1. X86 VTx 介绍
### 1.1 VMX 介绍

![](/kvm_blog/files/virt_cpu/vmx-ring.png)

- VMEntry: VMX root -> VMX non-root 
- VMExit: VMX nonroot -> VMX root 

- VMXON - enables VMX Operation.
- VMXOFF - disable VMX Operation.
- VMLAUNCH - 用于刚执行过 VMCLEAR 的第一次 VM Entry.
- VMRESUME - 用于执行过 VMLANUCH 的 VMCS 的后续 VM Entry.
- VMREAD - read from VMCS
- VMWRITE - write to VMCS


## 2. VMCS 介绍 ##
VMCS是Intel-x中一个很重要的数据结构，它占用一个page大小，由VMM分配，但是硬件是需要读写的，有点类似于页表。vmcs的各个域在manual中有说明，但是每个域在vmcs页中的具体位置是不知道的，程序员不用关心，只需要用相应的VMWRITE和VMREAD指令去访问。这样做的好处是，vmcs页中结构的具体layout可以透明的进行变动。

对于 KVM, VMCS 可以控制 CPU在 non-root 下的行为， 一般是 4KB的结构体。一般设置为 1就是要产生 VM Exit。 设置为 0 就是不产生 VM Exit。

下面从三个方面总结一下：一是vmcs组成部分；二是kvm中vmcs分配与初始化路径；三是kvm配置vmcs中一些重要的域。

### 2.1 VMCS组成部分
首先来看vmcs组成部分，这个可以参考"Intel SDM 3B 的 Chapter 24"，这里简单总结一下：

	 * 1. Guest State Area  
	 * 2. Host  State Area  
	 * 3. VM Execution Control Fields  
	 *   3.1 32bit pin-based exec ctrl  
	 *   3.2 32bit cpu-based exec ctrl  *     
	 *   3.3 32bit cpu-based secondary exec ctrl  
	 *   3.4 32bit exeception bitmap  
	 *   3.5 64bit physical addr of I/O bitmaps A and B(each is 4KB in size)  
	 *   3.6 64bit TSC-offset  
	 *   3.7 controls for APIC access  
	 * 4. VM-Exit Control Fields
	 *   4.1 32bit VM-Exit Controls
	 *   4.2 32+64bit VM-Exit Controls for MSRs
	 * 5. VM-Entry Control Fields
	 *   5.1 32bit VM-Entry Controls
	 *   5.2  VM-Entry Controls for Event Injection
	 *      5.2.1 32bit VM-Entry Interruption-information field
	 *      5.2.2 32bit VM-Entry exception error code
	 *      5.2.3 32bit VM-Entry instruction length
	 *      5.3 32+64bit VM-Entry Controls for MSRs  
	 * 6. VM-Exit Information Fields
 

### 2.2 VMCS 分配和初始化代码分析
再来看kvm分配与初始化vmcs的代码路径。我发现有两个路径都是要分配vmcs的：

第一：是kvm内核模块加载时，在hardware_setup中调用alloc_kvm_area，进而对每一个cpu调用alloc_vmcs_cpu。这里的每一个cpu应该是物理cpu了，为什么要对每个物理cpu都分配一个页的vmcs空间觉得有点奇怪，还没想明白。

另外，setup_vmcs_config很重要，是kvm默认对vmcs的一些配置，第三部分再讲，要注意的是它只是将配置记录到额外的一个结构vmcs_config中，并没有真正就写入vmcs了，后面真正写vmcs会用到这个结构。

	vmx_init(vmx.c)
	  |
	kvm_init(kvm_main.c)
	  |
	kvm_arch_init(kvm_main.c) --> kvm_arch_hardware_setup
	  |                                   |
	kvm_timer_init(x86.c)        kvm_x86_ops->hardware_setup(vmx.c)
	                                      |
	                           setup_vmcs_config(vmx.c)  --> alloc_kvm_area(vmx.c)
	                                      | for_each_cpu
	                               alloc_vmcs_cpu(vmx.c)

第二：是创建vcpu时，因为每个 vcpu 应该要单独对应一个vmcs。可以看到，这里也是用alloc_vmcs_cpu分配一个页的vmcs，所以我就觉得奇怪，既然每个vcpu都分配了vmcs页，为什么pcpu也要每个都分配一个vmcs页，不是可以像页表那样，用一个寄存器指向当前vcpu的vmcs页就行了么？另外，vmx_vcpu_setup很重要，它是真正地将配置写入vmcs页中去了。

	KVM_CREATE_VCPU ---> kvm_vm_ioctl (kvm_main.c)
	                           | 
	           kvm_vm_ioctl_create_vcpu(kvm_main.c)
	                           |
	           kvm_arch_vcpu_create(x86.c)
	                           |
	           kvm_x86_ops->vcpu_create(vmx_create_vcpu in vmc.c) 
	                              | 
	                        alloc_vmcs(vmx.c)   --->   vmx_vcpu_setup
	                              |                        |
	                        alloc_vmcs_cpu(vmx.c)      vmcs_writel  -->  guest_write_tsc

### 2.3 KVM 配置 VMCS的重要域名 
最后来看kvm对vmcs的一些重要配置。它几个部分的配置比较的分散：IO bitmap A and B在vmx_init中配置，毕竟vmcs中记录的只是IO bitmap的物理地址。具体的配置这里就不说了。 我现在关心的vmcs配置是：VM execution control、VM entry control及VM exit control三个部分。它们的具体配置是在setup_vmcs_config(注意这个是通用配置，后面特定的vcpu可以有修改)，其中重要的设置有：

-  PIN_BASED_EXT_INTR_MASK；标志着external interrupt会导致VMExit；
-  没有RDTSC_EXITING；标志着rdtsc指令不会导致VMExit，guest可以直接读取物理TSC；
-  CPU_BASED_USE_TSC_OFFSETTING；标志着读取的物理TSC还要加上一个TSC_OFFSET才得到guest TSC；
-  CPU_BASED_USE_IO_BITMAPS；标志着每个guest IO指令产不产生VMExit要去查IO bitmap；
-  SECONDARY_EXEC_ENABLE_EPT；标志着默认是打开ept特性的； 6. 没有VM_EXIT_ACK_INTR_ON_EXIT；我的理解是这样的—原来在guest模式下，中断是关闭的，但是会导致VMExit(上1配置)。Exit后kvm内核代码立刻开中断，这时必须能检测到这个中断。如果VMExit时就自动ack了，再开中断时就检测不到这个中断了。
-  1-6都是Execution control，至于Entry和Exit control在setup_vmcs_config中固定配置比较少，现在也不太关心，以后再总结。
 
 