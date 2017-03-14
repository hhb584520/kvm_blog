# 1.DMA介绍 #
## 1.1 DMA访问的原理 ##
    1.DMA(Driect Memory Access)访问的概述
    当系统内存想要与高速外设或者内存的不同区域之间进行大数据的快速传送时，查询和中断这两种方式不能满足要求：DMA就是为解决这样的问题提出来的。
(中断方式较之查询方式来说，可以提高CPU的利用率和保证对外设响应的实时性，但对于高速外设，中断方式不能满足数据传输速度的要求。因为，中断方式下，每次中断均需保存断点和现场；中断返回时，要恢复断点和现场。同时，进入中断和从中断返回均使CPU指令队列被清除。这些原因，使得中断方式难以满足高速外设对传输速度的要求。)
     采用DMA方式，在一段时间内，由DMA控制器取代CPU，获得总线控制权，从而实现内存与外设或者内存不同区域间的大量数据快速传递。

   2.DMA的工作过程
    1.当外设准备就绪，希望进行DMA传送时，向DMA控制器(DMAC)发出DMA请求信号(DREQ)。DMAC收到此信号后，向CPU发出总线请求信号(HOLD)。
　 2.CPU在完成当前总线操作后立即对DMA请求信号做出响应：先放弃对总线的控制(包括控制总线、数据总线、地址总线)，然后将有效的HLDA信号加到DMAC上。此时，CPU便放弃对总线的控制，DMAC获得总线的控制权。
　 3.DMAC获得总线的控制权后，向地址总线发出地址信号，指出传送过程需使用的内存地址(DMAC内部设有“地址寄存器”，在DMA操作过程中，每传送一字节数据，DMAC自动修改地址寄存器的值，以指向下一个内存地址)。同时，向外设发出DMA应答信号(DACK)，实现该外设与内存之间进行DMA传送。
　 4.在DMA传送期间，DMAC发出内存和外设的读/写信号。
　 5.为了决定数据块传输的字节数，在DMAC内部必须有一个“字节计数器”。在开始时，由软件设置数据块的长度，在DMA传送过程中，每传送一字节，字节计数器减1，减为0时，该次DMA传输结束。
　 6.DMA过程结束时，DMAC向CPU发出结束信号（撤消HOLD请求），将总线控制权交还CPU。

## 1.2 DMA传送的方式 ##
DMA传送的方式分为三种：I/O接口到存储器、存储器到I/O接口、存储器到存储器
   
- I/O接口到存储器方式

当想要由I/O接口到存储器的数据传送时，来自I/O接口的数据利用DMAC送出控制信号，将数据输送到数据总线D0-D7上，同时DMAC送出存储器单元地址及控制信号，将存于D0-D7上的数据写入选中的存储单元中。这样就完成了I/O接口到存储器的一个字节的传送。同时DMAC修改“地址寄存器”和“字节计数器”的内容。

- 存储器到I/O接口方式
    
与上面情况类似，在进行传送时，DMAC送出存储器地址和控制信号，将选中的存储器单元的内容读入数据总线的D0-D7上，然后，DMAC送出控制信号，将数据写到指定的端口中去，再DMAC修改“地址寄存器”和“字节计数器”的内容。

- 存储器到存储器方式
    
这种方式的DMA数据传送是用“数据块”方式传送（连续进行多个字节的传输，只有当“字节计数器”减为0，才完成一次DMA传送）。首先，送出存储器源的地址和控制信号，将选中内存单元的数据暂存，然后修改“地址寄存器”和“字节计数器”的值，接着，送出存储器目标的地址和控制信号，将暂存的数据通过数据总线写入到存储器的目标区域中，最后修改“地址寄存器”和“字节计数器”的内容，当“字节计数器”的值减少到零时可结束一次DMA。
 
## 1.3 S3C2410的DMA访问相关操作 ##
1.(本文采用S3C2410开发板)S3C2410支持4通道DMA控制器，在系统总线和外围总线之间。每个通道都能实现快速数据传送。每个通道能处理下面4种情况：
     1.源和目标器件都在系统总线AHB上。
     2.源器件在系统总线AHB上，目标器件在外围总线APB上。
     3.源器件在外围总线APB上，目标器件在系统总线AHB上。
     4.源和目标器件都在外围总线APB上。
DMA操作可以通过软件或者硬件来初始化。如果DCON寄存器选择采用硬件(H/W)DMA请求模式，那么DMA控制器可以从对应通道的DMA请求源中选择一个。如果DCON寄存器选择采用软件(S/W)DMA请求，那么这些DMA请求源将没有任何意义。DMA请求源如下表所列。

        nXDREQ0和nXDREQ1代表两个外部源，I2SSDO和I2SSDI分别代表IIS的传输和发送。

2.DMA工作模式
DMA的工作模式共有两种：单一服务模式和整体服务模式。
在单一服务模式下，一次DMA请求完成一项原子操作(操作不可间断) 。
在整体服务模式下，一次DMA请求完成一批原子操作，直到CURR_TC等于0，表示完成一次整体服务。 

3.DMA状态机描述
DMA可以有3种FSM(Finite State Machine，有限状态机)进行操作。
状态1：初始状态，DMA等待一个DMA请求，若请求到达，进入状态2。此阶段，DMA ACK和INT REQ 为0。
状态2：在此状态，DMA ACK 变为1，计数器CURR_TC的值从DCONn[19:0 ]装载。DMA ACK保持1，直到它被清0。
状态3：在此状态，对DMA进行原子操作的sub-FSM(子状态机)进行初始化。sub-FSM 从源地址读取数据后将数据写入目标地址。对于这种操作方式，数据大小和传输大小应给予考虑。在整体服务方式中，这种操作重复直到计数器CURR_TC变为0，然而在单一模式中只进行一次。当子FSM完成每个原子操作，主FSM倒计CURR_TC。另外，当CURR_TC为0 和中断设置DCONn[29]为1时，主FSM发出INT REQ（中断请求信号），假如以下任一种情况发生，要清除DMA ACK 。
     （1）在单一模式下，主FSM的3种状态执行完后就停止，并等待下一个DMA请求。对于每个原子操作，DMA ACK先置1，完成后清0。
     （2）在整体服务模式下，主FSM一直在状态3等待，直到CURR_TC变为0。因此，DMA ACK在整个传送过程中置1，CURR_TC变为0时则清0。

4.DMA基本时序
DMA服务意味着在DMA操作中执行一次读写周期，形成一个DMA操作。下图为S3C2410的DMA操作的基本时序。
nXDREQ请求生效并经过2CLK周期同步后，nXDACK响应并开始生效，但至少还要经过3CLK的周期延迟，DMA控制器才可获得总线的控制权，并开始数据传输。当DMA操作完成后，XnXDACK被设无效。

5.请求和答应的协议有两种：请求(Demand)和握手(Handshake)模式。(区别：在一个传输末尾,DMA检测两次同步的XnXDREQ的状态)
请求模式：如果XnXDREQ保持有效，则下一个传输开始马上开始，否则它会一直等到XnXDREQ有效。
握手模式：如果XnXDREQ无效，则DMA在两个同步周期内将XnXDACK设无效，否则它一直等到XnXDREQ无效。

6.传输大小
DMA的一次原子操作中，可以是Unit模式(传输一个Data Size)和brust模式(传输4个Data Size)。在DCON[28]中设置。

7.Data Size：指一次原子操作的数据位宽，可以为8，16，32。在DCON[21：20]中设置。
 
## 1.4 DMA控制器 ##
S3C2410每个DMA通道有9个控制寄存器，4个通道，共有36个寄存器。每个DMA通道有6个用于控制DMA传输，3个用于监控DMA控制器的状态。要进行DMA操作，首先需要对这些寄存器进行正确配置。下面介绍相关寄存器。(由于图太多，这里没有贴出来，大家可以在三星的S3C2401 Data Sheet里面找到对应的表)

- DMA初始化数据源(DISRC)寄存器组：分别对应着4个相关寄存器，主要用于初始化传输的数据源的基地址。
- DMA初始化数据源控制(DISRCC)寄存器：主要用于选择数据源的位置(在APB还是在AHB上)以及决定地址递增还是固定。
- DMA初始化目标(DIDST)寄存器：主要用于初始化传输目标开始地址。
- DMA初始化目标控制(DIDSTC)寄存器：主要用于选择目标的位置(在APB还是在AHB上)以及决定地址递增还是固定。
- DMA控制(DCON)寄存器：主要功能选择请求模式或者握手模式、选择DREQ/DACK同步、使能/禁止CURR_TC中断设置、选择Data Size、选择单一服务或整体服务模式、选择DMA请求源及初始化传输计数器等。
- DMA状态(DSTAT)寄存器：主要用于读取DMA控制器的状态及传输计数器的当前值。
- DMA当前源(DCSRC)寄存器：主要用于读取DMA控制器当前源地址的值。
- DMA当前目标(DCDST)寄存器：主要用于读取DMA控制器当前目标地址的值。
- 中断屏蔽触发(DMASKTRIG)寄存器：用于屏蔽PCI设备的中断请求。

## 1.5 详细设计 ##
S3C2410数据手册里可以找到有关DMA的寄存器的配置信息。根据实验目的，要想让实现内存间DMA传输，步骤如下：

- 首先当然是选择DMA通道；
- 设置DMA数据源地址(对DISRC操作)；
- 设置DMA数据源地址控制寄存器(对DISRCC操作)；
- 设置DMA目标地址(对DIDST操作)；
- 设置DMA数据源地址控制寄存器(对DIDSTC操作)；
- 初始化DMA控制寄存器(对DCON操作)；
- 打开DMA通道(DMASKTRIG操作)。

具体寄存器设置如下(假设选择DMA0通道)：

     rDISRC0=srcAddr;  //设置DMA数据源地址
     rDISRCC0=(0<<1) | (0<<0); //地址递增，数据源地址在AHB上
     rDIDST0=dstAdr;
     rDIDSTC0=(0<<1) | (0<<0);
     rDCON0=tc |(1UL<<31) | (1<<30) | (1<<29) | (burst<<28) | (1<<27) | (0<<23) | (1<<22) | (dsz<<20) | (tc);
     //定义DCON寄存器HS , AHB ,TC interrupt , whole, SW request mode , relaod off
    rDMASKTRIG0=(1<<1)|1;  //DMA on(打开DMA通道), SW_TRIG

## 1.6 编码设计 ##

- DMA传输函数void DMA_M2M(int ch, int srcAddr, int dstAddr, int tc, int dsz, int burst)
- DMA测试函数void Test_DMA(void)
- 测试主函数void Main(void)

	void DMA_M2M(int ch,int srcAddr,int dstAddr,int tc,int dsz,int burst)
	{
	    int i,time;
	    volatile U32 memSum0=0,memSum1=0;
	    DMA *pDMA;
	    int length=tc*(burst ? 4:1)*((dsz==0)+(dsz==1)*2+(dsz==2)*4);
	    
	    Uart_Printf("[DMA%d MEM2MEM Test]/n",ch);
	    switch(ch)
	    {
	    case 0:
	            pISR_DMA0 =(int)Dma0Done;//DMA0的中断服务程序
	           rINTMSK &=~(BIT_DMA0);  //允许DMA0中断
	            pDMA = (void *)0x4b000000;
	            break;
	    case 1:
	            pISR_DMA1 = (int)Dma1Done;
	            rINTMSK &= ~(BIT_DMA1);  
	            pDMA = (void *)0x4b000040;break;
	    case 2:
	        pISR_DMA2 = (int)Dma2Done;
	            rINTMSK &= ~(BIT_DMA2);  
	            pDMA = (void *)0x4b000080;break;
	    case 3:
	                pISR_DMA3 = (int)Dma3Done;
	                rINTMSK &= ~(BIT_DMA3);  
	                pDMA = (void *)0x4b0000c0; break;
	    }
	                                                                              
	                                              
	    Uart_Printf("DMA%d %8xh->%8xh,size=%xh(tc=%xh),dsz=%d,burst=%d/n",ch,srcAddr,dstAddr,length,tc,dsz,burst);
	    Uart_Printf("Initialize the src./n");
	    
	    for(i=srcAddr;i<(srcAddr+length);i+=4)
	    {
	    *((U32 *)i)=i^0x55aa5aa5;
	    memSum0+=i^0x55aa5aa5;
	    }
	
	    Uart_Printf("DMA%d start/n",ch);
	    
	    dmaDone=0;
	    
	    rDISRC0=srcAddr;
	    rDISRCC0=(0<<1)|(0<<0); // inc,AHB源来自于AHB
	    rDIDST0=dstAddr;
	    rDIDSTC0=(0<<1)|(0<<0); // inc,AHB目的为AHB
	    rDCON0=tc|(1UL<<31)|(1<<30)|(1<<29)|(burst<<28)|(1<<27)|/
	            (0<<23)|(1<<22)|(dsz<<20)|(tc);
	    //HS,AHB,TC interrupt,whole, SW request mode,relaod off
	    //    rINTMSK=~(BIT_DMA0);
	    rDMASKTRIG0=(1<<1)|1; //DMA on, SW_TRIG
	
	    //    Timer_Start(3);//128us resolution       
	    while(dmaDone==0);
	    //    time=Timer_Stop();
	    
	        printf("DMA%d end/n", ch);
	
	        // Uart_Printf("DMA transfer done. time=%f, %fMB/S/n",(float)time/ONESEC3,
	        // length/((float)time/ONESEC3)/1000000.);
	    rINTMSK |= (BIT_DMA0 | BIT_DMA1 | BIT_DMA2 | BIT_DMA3);
	    
	    for(i=dstAddr;i<dstAddr+length;i+=4) 
	    {
	            memSum1+=*((U32 *)i)=i^0x55aa5aa5;
	    }
	    
	    Uart_Printf("memSum0=%x,memSum1=%x/n",memSum0,memSum1);
	    if(memSum0==memSum1)
	            Uart_Printf("DMA test result--------O.K./n");
	    else 
	            Uart_Printf("DMA test result--------ERROR!!!/n");
	}
	
	
	void Test_DMA(void)
	{
	    //DMA Ch 0
	    DMA_M2M(0,0x31020000,0x31020000+0x80000,0x80000,0,0); //byte,single
	}
	
	void Main(void)
	{            
	    int i;
	    U8 key;
	    U32 mpll_val = 0 ;
	
	     Port_Init();  //端口初始化
	    Isr_Init();   //中断初始化
	    Uart_Init(0,115200);  //串口初始化 波特率为115200
	     Uart_Select(0);  //选者串口0
	     ChangeClockDivider(1,1);          // 1:2:4
	     ChangeMPllValue(0xa1,0x3,0x1);    // FCLK=202.8MHz
	
	        i=0;
	        Uart_Printf("/nBegin to start UART test,OK? (Y/N)/n");
	        key = Uart_Getch();
	        
	        if(key=='y'||key=='Y')
	                Test_DMA();
	        else
	                Uart_Printf("/nOh! You quit the test!/n");
	        Uart_Printf("/n====== UART Test End ======/n");
	}

## 2. DMA API ##

本文描述DMA API。更详细的介绍请参看Documentation/DMA-API-HOWTO.txt。

API分为两部分，第一部分描述API，第二部分描述可以支持非一致性内存机器的扩展API。你应该使用第一部分所描述的API，除非你知道你的驱动必须要支持非一致性平台。

## 2.1 DMA API ##

为了可以引用DMA API，你必须 #include <linux/dma-mapping.h>

1-1 使用大块DMA一致性缓冲区（dma-coherent buffers）

void * dma_alloc_coherent(struct device *dev, size_t size,
                    dma_addr_t *dma_handle, gfp_t flag)

一致性内存：设备对一块内存进行写操作，处理器可以立即进行读操作，而无需担心处理器高速缓存(cache)的影响。同样的，处理器对一块内存进行些操作，设备可以立即进行读操作。（在告诉设备读内存时，你可能需要确定刷新处理器的写缓存。）

此函数申请一段大小为size字节的一致性内存，返回两个参数。一个是dma_handle，它可以用作这段内存的物理地址。 另一个是指向被分配内存的指针（处理器的虚拟地址）。

注意：由于在某些平台上，使用一致性内存代价很高，比如最小的分配长度为一个页。因此你应该尽可能合并申请一致性内存的请求。最简单的办法是使用dma_pool函数调用（详见下文）。

参数flag（仅存在于dma_alloc_coherent中）运行调用者定义申请内存时的GFP_flags（详见kmalloc）。

void * 
dma_zalloc_coherent(struct device *dev, size_t size, 
                    dma_addr_t *dma_handle, gfp_t flag)

对dma_alloc_coherent()的封装，如果内存分配成功，则返回清零的内存。

void 
dma_free_coherent(struct device *dev, size_t size, void *cpu_addr, 
                    dma_addr_t dma_handle)

释放之前申请的一致性内存。dev, size及dma_handle必须和申请一致性内存的函数参数相同。cpu_addr必须为申请一致性内存函数的返回虚拟地址。

注意：和其他内存分配函数不同，这些函数必须要在中断使能的情况下使用。

1-2 使用小块DMA一致性缓冲区

如果要使用这部分DMA API，必须#include <linux/dmapool.h>。

许多驱动程序需要为DMA描述符或者I/O内存申请大量小块DMA一致性内存。你可以使用DMA 内存池，而不是申请以页为单位的内存块或者调用dma_alloc_coherent()。这种机制有点像struct kmem_cache，只是它利用了DMA一致性内存分配器，而不是调用 __get_free_pages()。同样地，DMA 内存池知道通用硬件的对齐限制，比如队列头需要N字节对齐。

struct dma_pool * 
dma_pool_create(const char *name, struct device *dev, 
                size_t size, size_t align, size_t alloc);

create( )函数为设备初始化DMA一致性内存的内存池。它必须要在可睡眠上下文调用。

name为内存池的名字（就像struct kmem_cache name一样）。dev及size就如dma_alloc_coherent()参数一样。align为设备硬件需要的对齐大小（单位为字节，必须为2的幂次方）。如果设备没有边界限制，可以设置该参数为0。如果设置为4096，则表示从内存池分配的内存不能超过4K字节的边界。

void *
dma_pool_alloc(struct dma_pool *pool, gfp_t gfp_flags, 
                dma_addr_t *dma_handle);

从内存池中分配内存。返回的内存同时满足申请的大小及对齐要求。设置GFP_ATOMIC可以确保内存分配被block，设置GFP_KERNEL（不能再中断上下文，不会保持SMP锁）允许内存分配被block。和dma_alloc_coherent()一样，这个函数会返回两个值：一个值是cpu可以使用的虚拟地址，另一个值是内存池设备可以使用的dma物理地址。

void 
dma_pool_free(struct dma_pool *pool, void *vaddr, 
                dma_addr_t addr);

返回内存给内存池。参数pool为传递给dma_pool_alloc()的pool，参数vaddr及addr为dma_pool_alloc()的返回值。

void 
dma_pool_destroy(struct dma_pool *pool);

内存池析构函数用于释放内存池的资源。这个函数在可睡眠上下文调用。请确认在调用此函数时，所有从该内存池申请的内存必须都要归还给内存池。

1-3 DMA寻址限制

int 
dma_supported(struct device *dev, u64 mask)

用来检测该设备是否支持掩码所表示的DMA寻址能力。比如mask为0x0FFFFFF，则检测该设备是否支持24位寻址。

返回1表示支持，0表示不支持。

注意：该函数很少用于检测是否掩码为可用的，它不会改变当前掩码设置。它是一个内部API而非供驱动者使用的外部API。

int 
dma_set_mask(struct device *dev, u64 mask)

检测该掩码是否合法，如果合法，则更新设备参数。即更新设备的寻址能力。

返回0表示成功，返回负值表示失败。

int 
dma_set_coherent_mask(struct device *dev, u64 mask)

检测该掩码是否合法，如果合法，则更新设备参数。即更新设备的寻址能力。

返回0表示成功，返回负值表示失败。

u64 
dma_get_required_mask(struct device *dev)

该函数返回平台可以高效工作的掩码。通常这意味着返回掩码是可以寻址到所有内存的最小值。检查该值可以让DMA描述符的大小尽量的小。

请求平台需要的掩码并不会改变当前掩码。如果你想利用这点，可以利用改返回值通过dma_set_mask()设置当前掩码。

1-4 流式DMA映射

dma_addr_t 
dma_map_single(struct device *dev, void *cpu_addr, size_t size,
                enum dma_data_direction direction)

映射一块处理器的虚拟地址，这样可以让外设访问。该函数返回内存的物理地址。

在dma_API中强烈建议使用表示DMA传输方向的枚举类型。

DMA_NONE    仅用于调试目的
DMA_TO_DEVICE    数据从内存传输到设备，可认为是写操作。
DMA_FROM_DEVICE    数据从设备传输到内存，可认为是读操作。
DMA_BIDIRECTIONAL    不清楚传输方向则可用该类型。

请注意：并非一台机器上所有的内存区域都可以用这个API映射。进一步说，对于内核连续虚拟地址空间所对应的物理地址并不一定连续（比如这段地址空间由vmalloc申请）。因为这种函数并未提供任何分散/聚集能力，因此用户在企图映射一块非物理连续的内存时，会返回失败。基于此原因，如果想使用该函数，则必须确保缓冲区的物理内存连续（比如使用kmalloc）。

更进一步，所申请内存的物理地址必须要在设备的dma_mask寻址范围内（dma_mask表示与设备寻址能力对应的位）。为了确保由kmalloc申请的内存在dma_mask中，驱动程序需要定义板级相关的标志位来限制分配的物理内存范围（比如在x86上，GFP_DMA用于保证申请的内存在可用物理内存的前16Mb空间，可以由ISA设备使用）。

同时还需注意，如果平台有IOMMU（设备拥有MMU单元，可以进行I/O内存总线和设备的映射，即总线地址和内存物理地址的映射），则上述物理地址连续性及外设寻址能力的限制就不存在了。当然为了方便起见，设备驱动开发者可以假设不存在IOMMU。

警告：内存一致性操作基于高速缓存行(cache line)的宽度。为了可以正确操作该API创建的内存映射，该映射区域的起始地址和结束地址都必须是高速缓存行的边界（防止在一个高速缓存行中有两个或多个独立的映射区域）。因为在编译时无法知道高速缓存行的大小，所以该API无法确保该需求。因此建议那些对高速缓存行的大小不特别关注的驱动开发者们，在映射虚拟内存时保证起始地址和结束地址都是页对齐的（页对齐会保证高速缓存行边界对齐的）。

DMA_TO_DEVICE    软件对内存区域做最后一次修改后，且在传输给设备前，需要做一次同步。一旦该使用该原语，内存区域可被视作设备只读缓冲区。如果设备需要对该内存区域进行写操作，则应该使用DMA_BIDIRECTIONAL（如下所示）

DMA_FROM_DEVICE    驱动在访问数据前必须做一次同步，因为数据可能被设备修改了。内存缓冲区应该被当做驱动只读缓冲区。如果驱动需要进行写操作，应该使用DMA_BIDIRECTIONAL（如下所示）。

DMA_BIDIRECTIONAL    需要特别处理：这意味着驱动并不确定内存数据传输到设备前，内存是否被修改了，同时也不确定设备是否会修改内存。因此，你必须需要两次同步双向内存：一次在内存数据传输到设备前（确保所有缓冲区数据改变都从处理器的高速缓存刷新到内存中），另一次是在设备可能访问该缓冲区数据前（确保所有处理器的高速缓存行都得到了更新，设备可能改变了缓冲区数据）。即在处理器写操作完成时，需要做一次刷高速缓存的操作，以确保数据都同步到了内存缓冲区中。在处理器读操作前，需要更新高速缓冲区的行，已确保设备对内存缓冲区的改变都同步到了高速缓冲区中。

void dma_unmap_single(struct device *dev, dma_addr_t dma_addr, size_t size,
                enum dma_data_direction direction)

取消先前的内存映射。传入该函数的所有参数必须和映射API函数的传入（包括返回）参数相同。

dma_addr_t dma_map_page(struct device *dev, struct page *page,
                    unsigned long offset, size_t size,
                    enum dma_data_direction direction)

void dma_unmap_page(struct device *dev, dma_addr_t dma_address, size_t size,
                enum dma_data_direction direction)

对页进行映射/取消映射的API。对其他映射API的注意事项及警告对此都使用。同样的，参数<offset>及<size>用于部分页映射，如果你对高速缓存行的宽度不清楚的话，建议你不要使用这些参数。

int dma_mapping_error(struct device *dev, dma_addr_t dma_addr)

在某些场景下，通过dma_map_single及dma_map_page创建映射可能会失败。驱动程序可以通过此函数来检测这些错误。一个非零返回值表示未成功创建映射，驱动程序需要采取适当措施（比如降低当前DMA映射使用率或者等待一段时间再尝试）。

int dma_map_sg(struct device *dev, struct scatterlist *sg,
        int nents, enum dma_data_direction direction)

返回值：被映射的物理内存块的数量（如果在分散/聚集链表中一些元素是物理地址或虚拟地址相邻的，切IOMMU可以将它们映射成单个内存块，则返回值可能比输入值<nents>小）。

请注意如果sg已经映射过了，其不能再次被映射。再次映射会销毁sg中的信息。

如果返回0，则表示dma_map_sg映射失败，驱动程序需要采取适当措施。驱动程序在此时做一些事情显得格外重要，一个阻塞驱动中断请求或者oopsing都总比什么都不做导致文件系统瘫痪强很多。

下面是个分散/聚集映射的例子，假设scatterlists已经存在。

int i, count = dma_map_sg(dev, sglist, nents, direction);
struct scatterlist *sg;

for_each_sg(sglist, sg, count, i) {
        hw_address[i] = sg_dma_address(sg);
        hw_len[i] = sg_dma_len(sg); 
}

其中nents为sglist条目的个数。

这种实现可以很方便将几个连续的sglist条目合并成一个（比如在IOMMU系统中，或者一些页正好是物理连续的）。

然后你就可以循环多次（可能小于nents次）使用sg_dma_address() 及sg_dma_len()来获取sg的物理地址及长度。

void 
dma_unmap_sg(struct device *dev, struct scatterlist *sg,
        int nhwentries, enum dma_data_direction direction)

取消先前分散/聚集链表的映射。所有参数和分散/聚集映射API的参数相同。

注意：<nents>是传入的参数，不一定是实际返回条目的数值。

void dma_sync_single_for_cpu(struct device *dev, dma_addr_t dma_handle, size_t size,
                                enum dma_data_direction direction)

void dma_sync_single_for_device(struct device *dev, dma_addr_t dma_handle, size_t size,
                                enum dma_data_direction direction)

void dma_sync_sg_for_cpu(struct device *dev, struct scatterlist *sg, int nelems,
                            enum dma_data_direction direction)

void dma_sync_sg_for_device(struct device *dev, struct scatterlist *sg, int nelems,
                            enum dma_data_direction direction)

为CPU及外设同步single contiguous或分散/聚集映射。

注意：你必须要做这个工作，

在CPU读操作前，此时缓冲区由设备通过DMA写入数据（DMA_FROM_DEVICE）

在CPU写操作后，缓冲区数据将通过DMA传输到设备（DMA_TO_DEVICE）

在传输数据到设备前后（DMA_BIDIRECTIONAL）

dma_addr_t 
dma_map_single_attrs(struct device *dev, void *cpu_addr, size_t size,
                    enum dma_data_direction dir,
                    struct dma_attrs *attrs)

void 
dma_unmap_single_attrs(struct device *dev, dma_addr_t dma_addr, 
                    size_t size, enum dma_data_direction dir,
                    struct dma_attrs *attrs)

int 
dma_map_sg_attrs(struct device *dev, struct scatterlist *sgl, 
                int nents, enum dma_data_direction dir,
                struct dma_attrs *attrs)

void 
dma_unmap_sg_attrs(struct device *dev, struct scatterlist *sgl, 
                    int nents, enum dma_data_direction dir,
                    struct dma_attrs *attrs)

这四个函数除了传入可选的struct dma_attrs*之外，其他和不带_attrs后缀的函数一样。

struct dma_attrs概述了一组DMA属性。struct dma_attrs详细定义请参见linux/dma-attrs.h。

DMA属性的定义是和体系结构相关的，并且Documentation/DMA-attributes.txt有详细描述。

如果struct dma_attrs* 为空，则这些函数可以认为和不带_attrs后缀的函数相同。

下面给出一个如何使用*_attrs 函数的例子，当进行DMA内存映射时，如何传入一个名为DMA_ATTR_FOO的属性：

#include <linux/dma-attrs.h> 
/* DMA_ATTR_FOO should be defined in linux/dma-attrs.h and
* documented in Documentation/DMA-attributes.txt */ 
...
        DEFINE_DMA_ATTRS(attrs);
        dma_set_attr(DMA_ATTR_FOO, &attrs);
        ....
        n = dma_map_sg_attrs(dev, sg, nents, DMA_TO_DEVICE, &attr);
        ....

在映射/取消映射的函数中，可以检查DMA_ATTR_FOO是否存在：

void whizco_dma_map_sg_attrs(struct device *dev, dma_addr_t dma_addr,
                            size_t size, enum dma_data_direction dir,
                            struct dma_attrs *attrs) 
{
        ....
        int foo = dma_get_attr(DMA_ATTR_FOO, attrs);
        ....
        if (foo)
            /* twizzle the frobnozzle */
        ....

## 2.2 高级DMA使用方法 ##

警告：下面这些DMA API在大多数情况下不应该被使用。因为它们为一些特殊的需求而准备的，大部分驱动程序并没有这些需求。

如果你不清楚如何确保桥接处理器和I/O设备之间的高速缓存行的一致性，你就根本不应该使用该部分所提到的API。

void * dma_alloc_noncoherent(struct device *dev, size_t size,
                            dma_addr_t *dma_handle, gfp_t flag)

平台会根据自身适应条件来选择返回一致性或非一致性内存，其他和dma_alloc_coherent()相同。在使用该函数时，你应该确保在驱动程序中对该内存做了正确的和必要的同步操作。

注意，如果返回一致性内存，则它会确保所有同步操作都变成空操作。

警告：处理非一致性内存是件痛苦的事情。如果你确信你的驱动要在非常罕见的平台上（通常是非PCI平台）运行，这些平台无法分配一致性内存时，你才可以使用该API。

void dma_free_noncoherent(struct device *dev, size_t size, void *cpu_addr,
                            dma_addr_t dma_handle)

释放由非一致性API申请的内存。

int dma_get_cache_alignment(void)

返回处理器高速缓存对齐值。应该注意在你打算映射内存或者做局部映射时，该值为最小对齐值。

注意：该API可能返回一个比实际缓存行的大的值。通常为了方便对齐，该值为2的幂次方。

void dma_cache_sync(struct device *dev, void *vaddr, size_t size, 
                enum dma_data_direction direction)

对由dma_alloc_noncoherent()申请的内存做局部映射，其实虚拟地址为vaddr。在做该操作时，请注意缓存行的边界。

int dma_declare_coherent_memory(struct device *dev, dma_addr_t bus_addr,
                            dma_addr_t device_addr, size_t size, int flags)

当设备需要一段一致性内存时，申请由dma_alloc_coherent分配的一段内存区域。

flag 可以由下面这些标志位进行或操作。

DMA_MEMORY_MAP    请求由dma_alloc_coherent()申请的内存为直接可写。

DMA_MEMORY_IO    请求由dma_alloc_coherent()申请的内存可以通过read/write/memcpy_toio等函数寻址到。

flag必须包含上述其中一个或者两个标志位。

DMA_MEMORY_INCLUDES_CHILDREN   

DMA_MEMORY_EXCLUSIVE   

为了使操作简单化，每个设备只能申申明一个该内存区域。

处于效率考虑的目的，大多数平台选择页对齐的区域。对于更小的内存分配，可以使用dma_pool() API。

void 
dma_release_declared_memory(struct device *dev)

从系统中移除先前申明的内存区域。该函数不会检测当前区域是否在使用。确保该内存区域当前没有被使用这是驱动程序的事情。

void * 
dma_mark_declared_memory_occupied(struct device *dev, 
                dma_addr_t device_addr, size_t size)

该函数用于覆盖特殊内存区域（dma_alloc_coherent()会分配出第一个可用内存区域）。

返回值为指向该内存的处理器虚拟地址，或者如果其中福分区域被覆盖，则返回一个错误（通过PRT_ERR()）。

第三部分  调试驱动程序对DMA-API的使用情况

DMA-API如前文所述有一些限制。在支持硬件IOMMU的系统中，驱动程序不能违反这些限制将变得更加重要。最糟糕的情况是，如果违反了这些限制准则，会导致数据出错知道摧毁文件系统。

为了debug驱动程序及发现使用DMA-API时的bug，检测代码可以编译到kernel中，它们可以告诉开发者那些违规行为。如果你的体系结构支持，你可以选择编译选项“Enable debugging of DMA-API usage”，使能这个选项会影响系统性能，所以请勿在产品内核中加入该选项。

如果你用使能debug选项的内核启动，那么它会记录哪些设备会使用什么DMA内存。如果检测到错误信息，则会在内核log中打印一些警告信息。下面是一个警告提示的例子：

------------[ cut here ]------------
WARNING: at /data2/repos/linux-2.6-iommu/lib/dma-debug.c:448 
        check_unmap+0x203/0x490() 
Hardware name: 
forcedeth 0000:00:08.0: DMA-API: device driver frees DMA memory with wrong 
        function [device address=0x00000000640444be] [size=66 bytes] [mapped as 
single] [unmapped as page] 
Modules linked in: nfsd exportfs bridge stp llc r8169 
Pid: 0, comm: swapper Tainted: G W 2.6.28-dmatest-09289-g8bb99c0 #1 
Call Trace: 
<IRQ> [<ffffffff80240b22>] warn_slowpath+0xf2/0x130
[<ffffffff80647b70>] _spin_unlock+0x10/0x30
[<ffffffff80537e75>] usb_hcd_link_urb_to_ep+0x75/0xc0
[<ffffffff80647c22>] _spin_unlock_irqrestore+0x12/0x40
[<ffffffff8055347f>] ohci_urb_enqueue+0x19f/0x7c0
[<ffffffff80252f96>] queue_work+0x56/0x60
[<ffffffff80237e10>] enqueue_task_fair+0x20/0x50
[<ffffffff80539279>] usb_hcd_submit_urb+0x379/0xbc0
[<ffffffff803b78c3>] cpumask_next_and+0x23/0x40
[<ffffffff80235177>] find_busiest_group+0x207/0x8a0
[<ffffffff8064784f>] _spin_lock_irqsave+0x1f/0x50
[<ffffffff803c7ea3>] check_unmap+0x203/0x490
[<ffffffff803c8259>] debug_dma_unmap_page+0x49/0x50
[<ffffffff80485f26>] nv_tx_done_optimized+0xc6/0x2c0
[<ffffffff80486c13>] nv_nic_irq_optimized+0x73/0x2b0
[<ffffffff8026df84>] handle_IRQ_event+0x34/0x70
[<ffffffff8026ffe9>] handle_edge_irq+0xc9/0x150
[<ffffffff8020e3ab>] do_IRQ+0xcb/0x1c0
[<ffffffff8020c093>] ret_from_intr+0x0/0xa
<EOI> <4>---[ end trace f6435a98e2a38c0e ]---

驱动开发者可以通过DMA-API的栈回溯信息找出什么导致这些警告。

默认情况下只有第一个错误会打印警告信息，其他错误不会打印警告信息。这种机制保证当前警告打印信息不会冲了你的内核信息。为了debug设备驱动，可以通过debugfs禁止该功能。请看下面详细的defbugfs接口文档。

调试DMA-API代码的debugfs目录叫dma-api/。下列文件存在于该个目录下：

dma-api/all_errors    该文件节点包含一个数值。如果该值不为零，则调试代码会在遇到每个错误的时候都打印警告信息。请注意这个选项会轻易覆盖你的内核信息缓冲区。

dma-api/disabled    只读文件节点，如果禁止调试代码则显示字符“Y”。当系统没有足够内存或者在系统启动时禁止调试功能时，该节点显示“Y”。

dma-api/error_count    只读文件节点，显示发现错误的次数。

dma-api/num_errors    该文件节点显示在打印停止前一共打印多少个警告信息。该值在系统启动时初始化为1，通过写该文件节点来设置该值。

dma-api/min_free_entries    只读文件节点，显示分配器记录的可用dma_debug_entries的最小数目。如果该值变为零，则禁止调试代码。

dma-api/num_free_entries    当前分配器可用dma_debug_entries的数目。

dma-api/driver-filter    通过向该文件节点写入驱动的名字来限制特定驱动的调试输出。如果向该节点输入空字符，则可以再次看到全部错误信息。

如果这些代码默认编译到你的内核中，该调试功能被默认打开。如果在启动时你不想使用该功能，则可以设置“dma_debug=off”作为启动参数，该参数会禁止该功能。如果你想在系统启动后再次打开该功能，则必须重启系统。

如果你指向看到特定设备驱动的调试信息，则可以设置“dma_debug_driver=<drivername>”作为参数。它会在系统启动时使能驱动过滤器。调试代码只会打印和该驱动相关的错误信息。过滤器可以通过debugfs来关闭或者改变。

如果该调试功能在系统运行时自动关闭，则可能是超出了dma_debug_entries的最大限制。这些debug条目在启动时就分配好了，条目数量由每个体系结构自己定义。你可以在启动时使用“dma_debug_entries=<your_desired_number>”来重写该值。 

参考文献

[1] documentation/DMA-API.txt