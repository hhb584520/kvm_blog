## 全虚（同步）： ##
 
![](/kvm_blog/img/xen_full_virt.png)

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

## 半虚（异步）： ##

![](/kvm_blog/img/xen_para_virt.png)

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
 
