
# KVM Create VM 流程 #

这里主要介绍基于x86平台的Guest Os, Qemu, Kvm工作流程，如图，通过KVM APIs可以将qemu的command传递到kvm：

![](/kvm_blog/img/qemu_kvm_create_vm.png)


## 1.创建VM ##

	s->fd = qemu_open("/dev/kvm", O_RDWR);
	s->vmfd = vm_fd = ioctl(system_fd, KVM_CREATE_VM, xxx);

## 2.创建VCPU ##

	vcpu_fd = kvm_vm_ioctl(vm_fd, VM_CREATE_VCPU, xxx);
 	machine->init(&arg)函数主要初始化硬件设备,并且调用qemu_init_vcpu为每一个vcpu创建一个线程,线程执行的函数为qemu_kvm_cpu_thread_fn.从qemu main到qemu_init_vcpu之间函数调用关系涉及到一些函数指针的赋值源码比较难于读懂,以下是使用gdb调试打出其调用关系.

	#0 qemu_init_vcpu (cpu=0x55555681ea90) at /home/dashu/kvm/qemu/qemu-dev-zwu/cpus.c:1084  
	#1 0x0000555555909f1e in x86_cpu_realizefn (dev=0x55555681ea90, errp=0x7fffffffd8f8) at /home/dashu/kvm/qemu/qemu-dev-zwu/target-i386/cpu.c:2399  
	#2 0x00005555556c768a in device_set_realized (obj=0x55555681ea90, value=true, err=0x7fffffffda88) at hw/core/qdev.c:699  
	#3 0x000055555580b93f in property_set_bool (obj=0x55555681ea90, v=0x5555565bab20, opaque=0x5555565375a0, name=0x555555a01f88 "realized", errp=0x7fffffffda88) at qom/object.c:1300  
	#4 0x000055555580a484 in object_property_set (obj=0x55555681ea90, v=0x5555565bab20, name=0x555555a01f88 "realized", errp=0x7fffffffda88) at qom/object.c:788  
	#5 0x000055555580bbea in object_property_set_qobject (obj=0x55555681ea90, value=0x555556403e40, name=0x555555a01f88 "realized", errp=0x7fffffffda88) at qom/qom-qobject.c:24  
	#6 0x000055555580a770 in object_property_set_bool (obj=0x55555681ea90, value=true, name=0x555555a01f88 "realized", errp=0x7fffffffda88) at qom/object.c:851  
	#7 0x00005555558a7de0 in pc_new_cpu (cpu_model=0x555555a0200b "qemu64", apic_id=0, icc_bridge=0x55555655b2c0, errp=0x7fffffffdac8) at /home/dashu/kvm/qemu/qemu-dev-zwu/hw/i386/pc.c:922  
	#8 0x00005555558a7fed in pc_cpus_init (cpu_model=0x555555a0200b "qemu64", icc_bridge=0x55555655b2c0) at /home/dashu/kvm/qemu/qemu-dev-zwu/hw/i386/pc.c:978  
	#9 0x00005555558a923b in pc_init1 (system_memory=0x5555562a7240, system_io=0x5555562a7f60, ram_size=1073741824, boot_device=0x555555a0248a "cad", kernel_filename=0x0, kernel_cmdline=0x5555559f85be "",   
	initrd_filename=0x0, cpu_model=0x0, pci_enabled=1, kvmclock_enabled=1) at /home/dashu/kvm/qemu/qemu-dev-zwu/hw/i386/pc_piix.c:105  
	#10 0x00005555558a9a36 in pc_init_pci (args=0x7fffffffdf10) at /home/dashu/kvm/qemu/qemu-dev-zwu/hw/i386/pc_piix.c:245  
	#11 0x00005555558a9a7f in pc_init_pci_1_6 (args=0x7fffffffdf10) at /home/dashu/kvm/qemu/qemu-dev-zwu/hw/i386/pc_piix.c:255  
	#12 0x00005555558584fe in main (argc=10, argv=0x7fffffffe148, envp=0x7fffffffe1a0) at vl.c:4317  

## 3.运行KVM ##

	status = kvm_vcpu_ioctl(vcpu_fd, KVM_RUN, xxx);

Qemu通过KVM APIs进入KVM后，KVM会切入Guest OS，假如Guest OS运行中，需要访问IO等，也就是说要访问physical device，那么Qemu与KVM就要进行emulate。 如果是KVM emulate的则由KVM emulate，然后切回Guest OS。如果是Qemu emulate的，则从KVM中进入Qemu，等Qemu中的device model执行完emulate之后，再次在Qemu中调用kvm_vcpu_ioctl(vcpu_fd, KVM_RUN, xxx)进入KVM运行，然后再切回Guest OS.

![](/kvm_blog/img/kvm_code_analy.png)

Qemu是一个应用程序，所以入口函数当然是main函数，但是一些被type_init修饰的函数会在main函数之前运行。这里分析的代码是emulate x86 的一款i440板子。main函数中会调用在main函数中会调用kvm_init函数来创建一个VM(virtual machine)，然后调用机器硬件初始化相关的函数，对PCI，memory等进行emulate。然后调用qemu_thread_create创建线程，这个函数会调用pthread_create创建一个线程，每个VCPU依靠一个线程来运行。在线程的处理函数qemu_kvm_cpu_thread_fn中，会调用kvm_init_vcpu来创建一个VCPU(virtual CPU)，然后调用kvm_vcpu_ioctl，参数KVM_RUN，这样就进入KVM中了。进入KVM中第一个执行的函数名字相同，也叫kvm_vcpu_ioctl，最终会调用到kvm_x86_ops->run()进入到Guest OS，如果Guest OS要写某个端口，会产生一条IO instruction，这时会从Guest OS中退出，调用kvm_x86_ops->handle_exit函数，其实这个函数被赋值为vmx_handle_exit，最终会调用到kvm_vmx_exit_handlers[exit_reason](vcpu)，kvm_vmx_exit_handlers是一个函数指针，会根据产生事件的类型来匹配使用那个函数。这里因为是ioport访问产生的退出，所以选择handle_io函数。

	5549static int (*kvm_vmx_exit_handlers[])(struct kvm_vcpu *vcpu) = {
	5550        [EXIT_REASON_EXCEPTION_NMI]           = handle_exception,
	5551        [EXIT_REASON_EXTERNAL_INTERRUPT]      = handle_external_interrupt,
	5552        [EXIT_REASON_TRIPLE_FAULT]            = handle_triple_fault,
	5553        [EXIT_REASON_NMI_WINDOW]              = handle_nmi_window,
	5554        [EXIT_REASON_IO_INSTRUCTION]          = handle_io,
	5555        [EXIT_REASON_CR_ACCESS]               = handle_cr,
	5556        [EXIT_REASON_DR_ACCESS]               = handle_dr,
	5557        [EXIT_REASON_CPUID]                   = handle_cpuid,
	5558        [EXIT_REASON_MSR_READ]                = handle_rdmsr,
	5559        [EXIT_REASON_MSR_WRITE]               = handle_wrmsr,
	5560        [EXIT_REASON_PENDING_INTERRUPT]       = handle_interrupt_window,
	5561        [EXIT_REASON_HLT]                     = handle_halt,
	5562        [EXIT_REASON_INVD]                    = handle_invd,
	5563        [EXIT_REASON_INVLPG]                  = handle_invlpg,
	5564        [EXIT_REASON_VMCALL]                  = handle_vmcall,
	5565        [EXIT_REASON_VMCLEAR]                 = handle_vmclear,
	5566        [EXIT_REASON_VMLAUNCH]                = handle_vmlaunch,
	5567        [EXIT_REASON_VMPTRLD]                 = handle_vmptrld,
	5568        [EXIT_REASON_VMPTRST]                 = handle_vmptrst,
	5569        [EXIT_REASON_VMREAD]                  = handle_vmread,
	5570        [EXIT_REASON_VMRESUME]                = handle_vmresume,
	5571        [EXIT_REASON_VMWRITE]                 = handle_vmwrite,
	5572        [EXIT_REASON_VMOFF]                   = handle_vmoff,
	5573        [EXIT_REASON_VMON]                    = handle_vmon,
	5574        [EXIT_REASON_TPR_BELOW_THRESHOLD]     = handle_tpr_below_threshold,
	5575        [EXIT_REASON_APIC_ACCESS]             = handle_apic_access,
	5576        [EXIT_REASON_WBINVD]                  = handle_wbinvd,
	5577        [EXIT_REASON_XSETBV]                  = handle_xsetbv,
	5578        [EXIT_REASON_TASK_SWITCH]             = handle_task_switch,
	5579        [EXIT_REASON_MCE_DURING_VMENTRY]      = handle_machine_check,
	5580        [EXIT_REASON_EPT_VIOLATION]           = handle_ept_violation,
	5581        [EXIT_REASON_EPT_MISCONFIG]           = handle_ept_misconfig,
	5582        [EXIT_REASON_PAUSE_INSTRUCTION]       = handle_pause,
	5583        [EXIT_REASON_MWAIT_INSTRUCTION]       = handle_invalid_op,
	5584        [EXIT_REASON_MONITOR_INSTRUCTION]     = handle_invalid_op,
	5585};

如果KVM中的handle_io函数可以处理，那么处理完了再次切入Guest OS。如果是在Qemu中emulate，那么在KVM中的代码执行完后，会再次回到Qemu中，调用Qemu中的kvm_handle_io函数，如果可以处理，那么再次调用kvm_vcpu_ioctl，参数KVM_RUN，进入KVM，否则出错退出。

## 4. KVM API 类型 ##

### 4.1 System指令(system ioctls) ###

针对虚拟化系统的全局性参数设置和用于虚拟机创建等控制操作。
KVM_GET_API_VERSION          查询当前 KVM API 的版本。
KVM_CREATE_VM                    创建 KVM 虚拟机。
KVM_GET_MSR_INDEX_LIST    创建 MSR 索引列表。
KVM_CHECK_EXTENSION        检查扩展支持情况。
KVM_GET_VCPU_MMAP_SIZE 运行虚拟机和用户态空间共享的一片内存区域大小。
    
### 4.2 VM指令(vm ioctls) ###
针对虚拟化系统的全局性参数设置和用于虚拟机创建等控制操作。
KVM_CREATE_VCPU                为已经创建好的VM添加vCPU。
KVM_RUN                                根据 kvm_run 结构体的信息，启动 VM 虚拟机。
        ...........
 
### 4.3 VM指令(vm ioctls) ###
针对虚拟化系统的全局性参数设置和用于虚拟机创建等控制操作。
KVM_CREATE_VCPU         为已经创建好的VM添加vCPU。
KVM_RUN                 根据 kvm_run 结构体的信息，启动 VM 虚拟机。

main->cpu_init->cpu_x86_init->x86_cpu_realize->qemu_init_vcpu->qemu_kvm_start_vcpu->qemu_kvm_cpu_thread_fn->kvm_init_vcpu->mmap_size = kvm_ioctl(s, KVM_GET_VCPU_MMAP_SIZE, 0);

## 5. QEMU的核心初始化流程 ##
客户系统运行之前，QEMU作为全系统模拟软件，需要为客户系统模拟出CPU、主存以及I/O设备，使客户系统就像运行在真实硬件之上，而不用对客户系统代码做修改。如概览部分所示，由用户为客户系统指定需要的虚拟CPU资源（包括CPU核心数，SOCKET数目，每核心的超线程数，是否开启NUMA等等），虚拟内存资源，具体参数设置参见${QEMU}/qemu-options.hx。创建QEMU主线程，执行QEMU系统的初始化，在初始化的过程中针对每一个虚拟CPU，单独创建一个posix线程。每当一个虚拟CPU线程被调度到物理CPU上执行时，该VCPU对应的一套完整的寄存器集合被加载到物理CPU上，通过VM-LAUNCH或VM-RESUME指令切换到非根模式执行。直到该线程时间片到，或者其它中断引发虚拟机退出，VCPU退出到根模式，进行异常处理。

如下图所示，当用户运行QEMU的System Mode的可执行文件时，QEMU从${QEMU}/vl.c的main函数执行主线程。以下着重分析，客户系统启动之前，QEMU所做的初始化工作：

## 参考资料: ##
1. qemu-kvm的初始化与客户系统的执行:http://blog.csdn.net/lux_veritas/article/details/9383643
2. 内核虚拟化kvm/qemu----guest os,kvm,qemu工作流程:http://www.360doc.com/content/12/0619/13/7982302_219186951.shtml
 