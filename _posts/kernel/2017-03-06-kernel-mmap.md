
# 1. mmap 介绍 #
共享内存可以说是最有用的进程间通信方式，也是最快的IPC形式, 因为进程可以直接读写内存，而不需要任何数据的拷贝。对于像管道和消息队列等通信方式，则需要在内核和用户空间进行四次的数据拷贝，而共享内存则只拷贝两次数据: 一次从输入文件到共享内存区，另一次从共享内存区到输出文件。实际上，进程之间在共享内存时，并不总是读写少量数据后就解除映射，有新的通信时，再重新建立共享内存区域。而是保持共享区域，直
到通信完毕为止，这样，数据内容一直保存在共享内存中，并没有写回文件。共享内存中的内容往往是在解除映射时才写回文件的。因此，采用共享内存的通信方式效率是非常高的。

## 1.1 传统文件访问 ##
UNIX访问文件的传统方法是用open打开它们, 如果有多个进程访问同一个文件, 则每一个进程在自己的地址空间都包含有该文件的副本,这不必要地浪费了存储空间. 下图说明了两个进程同时读一个文件的同一页的情形. 系统要将该页从磁盘读到高速缓冲区中, 每个进程再执行一个存储器内的复制操作将数据从高速缓冲区读到自己的地址空间.

![](/kvm_blog/files/kernel/legacy_file_access.png)
  
## 1.2 共享存储映射 ##
现在考虑另一种处理方法: 进程A和进程B都将该页映射到自己的地址空间, 当进程A第一次访问该页中的数据时, 它生成一个缺页中断. 内核此时读入这一页到内存并更新页表使之指向它.以后, 当进程B访问同一页面而出现缺页中断时, 该页已经在内存, 内核只需要将进程B的页表登记项指向次页即可. 如下图所示: 

![](/kvm_blog/files/kernel/sharemem_file_access.png)

## 1.3 mmap()及其相关系统调用 ##
 
mmap()系统调用使得进程之间通过映射同一个普通文件实现共享内存。普通文件被映射到进程地址空间后，这样文件中的位置直接就有对应的内存地址，进程可以向访问普通内存一样对文件进行访问，对文件的读写可以直接用指针来做而不需要read/write函数。
 


![](/kvm_blog/files/kernel/mmap.png)


基于文件的映射，在mmap和munmap执行过程的任何时刻，被映射文件的st_atime可能被更新。如果st_atime字段在前述的情况下没有得到更新，首次对映射区的第一个页索引时会更新该字段的值。用PROT_WRITE 和 MAP_SHARED标志建立起来的文件映射，其st_ctime 和 st_mtime在对映射区写入之后，但在msync()通过MS_SYNC 和 MS_ASYNC两个标志调用之前会被更新。

	用法：
	#include <sys/mman.h>
	void *mmap(void *start, size_t length, int prot, int flags,
	int fd, off_t offset);
	int munmap(void *start, size_t length);

	返回说明：
	成功执行时，mmap()返回被映射区的指针，munmap()返回0。失败时，mmap()返回MAP_FAILED[其值为(void *)-1]，munmap返回-1。errno被设为以下的某个值
	EACCES：访问出错
	EAGAIN：文件已被锁定，或者太多的内存已被锁定
	EBADF：fd不是有效的文件描述词
	EINVAL：一个或者多个参数无效
	ENFILE：已达到系统对打开文件的限制
	ENODEV：指定文件所在的文件系统不支持内存映射
	ENOMEM：内存不足，或者进程已超出最大内存映射数量
	EPERM：权能不足，操作不允许
	ETXTBSY：已写的方式打开文件，同时指定MAP_DENYWRITE标志
	SIGSEGV：试着向只读区写入
	SIGBUS：试着访问不属于进程的内存区
	
	参数：
	start：映射区的开始地址。
	
	length：映射区的长度。
	
	prot：期望的内存保护标志，不能与文件的打开模式冲突。是以下的某个值，可以通过or运算合理地组合在一起
	PROT_EXEC //页内容可以被执行
	PROT_READ //页内容可以被读取
	PROT_WRITE //页可以被写入
	PROT_NONE //页不可访问
	
	flags：指定映射对象的类型，映射选项和映射页是否可以共享。它的值可以是一个或者多个以下位的组合体
	MAP_FIXED //使用指定的映射起始地址，如果由start和len参数指定的内存区重叠于现存的映射空间，重叠部分将会被丢弃。如果指定的起始地址不可用，操作将会失败。并且起始地址必须落在页的边界上。
	MAP_SHARED //与其它所有映射这个对象的进程共享映射空间。对共享区的写入，相当于输出到文件。直到msync()或者munmap()被调用，文件实际上不会被更新。
	MAP_PRIVATE //建立一个写入时拷贝的私有映射。内存区域的写入不会影响到原文件。这个标志和以上标志是互斥的，只能使用其中一个。
	MAP_DENYWRITE //这个标志被忽略。
	MAP_EXECUTABLE //同上
	MAP_NORESERVE //不要为这个映射保留交换空间。当交换空间被保留，对映射区修改的可能会得到保证。当交换空间不被保留，同时内存不足，对映射区的修改会引起段违例信号。
	MAP_LOCKED //锁定映射区的页面，从而防止页面被交换出内存。
	MAP_GROWSDOWN //用于堆栈，告诉内核VM系统，映射区可以向下扩展。
	MAP_ANONYMOUS //匿名映射，映射区不与任何文件关联。
	MAP_ANON //MAP_ANONYMOUS的别称，不再被使用。
	MAP_FILE //兼容标志，被忽略。
	MAP_32BIT //将映射区放在进程地址空间的低2GB，MAP_FIXED指定时会被忽略。当前这个标志只在x86-64平台上得到支持。
	MAP_POPULATE //为文件映射通过预读的方式准备好页表。随后对映射区的访问不会被页违例阻塞。
	MAP_NONBLOCK //仅和MAP_POPULATE一起使用时才有意义。不执行预读，只为已存在于内存中的页面建立页表入口。
	
	fd：有效的文件描述词。如果MAP_ANONYMOUS被设定，为了兼容问题，其值应为-1。
	
	offset：被映射对象内容的起点。offset参数一般设为0，表示从文件头开始映射, 必须是页大小的整数倍（在32位体系统结构上通常是4K）。

	#include <sys/mman.h>
	
	int munmap( void * addr, size_t len ) 
	该调用在进程地址空间中解除一个映射关系，addr是调用mmap()时返回的地址，len是映射区的大小。当映射关系解除后，对原来映射地址的访问将导致段错误发生。 

	#include <sys/mman.h>
	
	int msync ( void * addr , size_t len, int flags) 
	一般说来，进程在映射空间的对共享内容的改变并不直接写回到磁盘文件中，往往在调用munmap（）后才执行该操作。可以通过调用msync()实现磁盘上文件内容与共享内存区的内容一致。  


## 1.4 对mmap()返回地址的访问 ##
linux采用的是页式管理机制。对于用mmap()映射普通文件来说，进程会在自己的地址空间新增一块空间，空间大
小由mmap()的len参数指定，注意，进程并不一定能够对全部新增空间都能进行有效访问。进程能够访问的有效地址大小取决于文件被映射部分的大小。简单的说，能够容纳文件被映射部分大小的最少页面个数决定了  进程从mmap()返回的地址开始，能够有效访问的地址空间大小。超过这个空间大小，内核会根据超过的严重程度返回发送不同的信号给进程。可用如下图示说明：
 
![](/kvm_blog/files/kernel/mmap_address_map.gif)

总结一下就是, 文件大小, mmap的参数 len 都不能决定进程能访问的大小, 而是容纳文件被映射部分的最小页面数决定
进程能访问的大小. 下面看一个实例:
 
	#include <sys/mman.h>  
	#include <sys/types.h>  
	#include <sys/stat.h>  
	#include <fcntl.h>  
	#include <unistd.h>  
	#include <stdio.h>  
	  
	int main(int argc, char** argv)  
	{  
	    int fd,i;  
	    int pagesize,offset;  
	    char *p_map;  
	    struct stat sb;  
	  
	    /* 取得page size */  
	    pagesize = sysconf(_SC_PAGESIZE);  
	    printf("pagesize is %d\n",pagesize);  
	  
	    /* 打开文件 */  
	    fd = open(argv[1], O_RDWR, 00777);  
	    fstat(fd, &sb);  
	    printf("file size is %zd\n", (size_t)sb.st_size);  
	  
	    offset = 0;   
	    p_map = (char *)mmap(NULL, pagesize * 2, PROT_READ|PROT_WRITE,   
	            MAP_SHARED, fd, offset);  
	    close(fd);  
	      
	    p_map[sb.st_size] = '9';  /* 导致总线错误 */  
	    p_map[pagesize] = '9';    /* 导致段错误 */  
	  
	    munmap(p_map, pagesize * 2);  
	  
	    return 0;  
	}  

# 2. 操作例子 #

## 2.1 通过共享映射的方式修改文件 ##

范例中使用的测试文件 data.txt: 
Xml代码  
         
	aaaaaaaaa  
	bbbbbbbbb  
	ccccccccc  
	ddddddddd  

C代码  
         
	#include <sys/mman.h>  
	#include <sys/stat.h>  
	#include <fcntl.h>  
	#include <stdio.h>  
	#include <stdlib.h>  
	#include <unistd.h>  
	#include <error.h>  
	  
	#define BUF_SIZE 100  
	  
	int main(int argc, char **argv)  
	{  
	    int fd, nread, i;  
	    struct stat sb;  
	    char *mapped, buf[BUF_SIZE];  
	  
	    for (i = 0; i < BUF_SIZE; i++) {  
	        buf[i] = '#';  
	    }  
	  
	    /* 打开文件 */  
	    if ((fd = open(argv[1], O_RDWR)) < 0) {  
	        perror("open");  
	    }  
	  
	    /* 获取文件的属性 */  
	    if ((fstat(fd, &sb)) == -1) {  
	        perror("fstat");  
	    }  
	  
	    /* 将文件映射至进程的地址空间 */  
	    if ((mapped = (char *)mmap(NULL, sb.st_size, PROT_READ |   
	                    PROT_WRITE, MAP_SHARED, fd, 0)) == (void *)-1) {  
	        perror("mmap");  
	    }  
	  
	    /* 映射完后, 关闭文件也可以操纵内存 */  
	    close(fd);  
	  
	    printf("%s", mapped);  
	  
	    /* 修改一个字符,同步到磁盘文件 */  
	    mapped[20] = '9';  
	    if ((msync((void *)mapped, sb.st_size, MS_SYNC)) == -1) {  
	        perror("msync");  
	    }  
	  
	    /* 释放存储映射区 */  
	    if ((munmap((void *)mapped, sb.st_size)) == -1) {  
	        perror("munmap");  
	    }  
	  
	    return 0;  
	}  
 
## 2.2 私有映射无法修改文件 ##

	/* 将文件映射至进程的地址空间 */  

	if ((mapped = (char *)mmap(NULL, sb.st_size, PROT_READ |   
	                    PROT_WRITE, MAP_PRIVATE, fd, 0)) == (void *)-1) {  
	    perror("mmap");  
	}  
 

## 2.3 mmap 实现两个进程之间的通信 ##
两个程序映射同一个文件到自己的地址空间, 进程A先运行, 每隔两秒读取映射区域, 看是否发生变化. 
进程B后运行, 它修改映射区域, 然后退出, 此时进程A能够观察到存储映射区的变化

进程A的代码:
  
	#include <sys/mman.h>  
	#include <sys/stat.h>  
	#include <fcntl.h>  
	#include <stdio.h>  
	#include <stdlib.h>  
	#include <unistd.h>  
	#include <error.h>  
	  
	#define BUF_SIZE 100  
	  
	int main(int argc, char **argv)  
	{  
	    int fd, nread, i;  
	    struct stat sb;  
	    char *mapped, buf[BUF_SIZE];  
	  
	    for (i = 0; i < BUF_SIZE; i++) {  
	        buf[i] = '#';  
	    }  
	  
	    /* 打开文件 */  
	    if ((fd = open(argv[1], O_RDWR)) < 0) {  
	        perror("open");  
	    }  
	  
	    /* 获取文件的属性 */  
	    if ((fstat(fd, &sb)) == -1) {  
	        perror("fstat");  
	    }  
	  
	    /* 将文件映射至进程的地址空间 */  
	    if ((mapped = (char *)mmap(NULL, sb.st_size, PROT_READ |   
	                    PROT_WRITE, MAP_PRIVATE, fd, 0)) == (void *)-1) {  
	        perror("mmap");  
	    }  
	  
	    /* 文件已在内存, 关闭文件也可以操纵内存 */  
	    close(fd);  
	      
	    /* 每隔两秒查看存储映射区是否被修改 */  
	    while (1) {  
	        printf("%s\n", mapped);  
	        sleep(2);  
	    }  
	  
	    return 0;  
	}  
 
进程B的代码:
    
	#include <sys/mman.h>  
	#include <sys/stat.h>  
	#include <fcntl.h>  
	#include <stdio.h>  
	#include <stdlib.h>  
	#include <unistd.h>  
	#include <error.h>  
	  
	#define BUF_SIZE 100  
	  
	int main(int argc, char **argv)  
	{  
	    int fd, nread, i;  
	    struct stat sb;  
	    char *mapped, buf[BUF_SIZE];  
	  
	    for (i = 0; i < BUF_SIZE; i++) {  
	        buf[i] = '#';  
	    }  
	  
	    /* 打开文件 */  
	    if ((fd = open(argv[1], O_RDWR)) < 0) {  
	        perror("open");  
	    }  
	  
	    /* 获取文件的属性 */  
	    if ((fstat(fd, &sb)) == -1) {  
	        perror("fstat");  
	    }  
	  
	    /* 私有文件映射将无法修改文件 */  
	    if ((mapped = (char *)mmap(NULL, sb.st_size, PROT_READ |   
	                    PROT_WRITE, MAP_SHARED, fd, 0)) == (void *)-1) {  
	        perror("mmap");  
	    }  
	  
	    /* 映射完后, 关闭文件也可以操纵内存 */  
	    close(fd);  
	  
	    /* 修改一个字符 */  
	    mapped[20] = '9';  
	   
	    return 0;  
	}  
 
## 2.4 mmap 通过匿名映射实现父子进程通信 ##
   
	#include <sys/mman.h>  
	#include <stdio.h>  
	#include <stdlib.h>  
	#include <unistd.h>  
	  
	#define BUF_SIZE 100  
	  
	int main(int argc, char** argv)  
	{  
	    char    *p_map;  
	  
	    /* 匿名映射,创建一块内存供父子进程通信 */  
	    p_map = (char *)mmap(NULL, BUF_SIZE, PROT_READ | PROT_WRITE,  
	            MAP_SHARED | MAP_ANONYMOUS, -1, 0);  
	  
	    if(fork() == 0) {  
	        sleep(1);  
	        printf("child got a message: %s\n", p_map);  
	        sprintf(p_map, "%s", "hi, dad, this is son");  
	        munmap(p_map, BUF_SIZE); //实际上，进程终止时，会自动解除映射。  
	        exit(0);  
	    }  
	  
	    sprintf(p_map, "%s", "hi, this is father");  
	    sleep(2);  
	    printf("parent got a message: %s\n", p_map);  
	  
	    return 0;  
	}  
 
# 3. mmap 进行内存映射的原理 #

mmap系统调用的最终目的是将,设备或文件映射到用户进程的虚拟地址空间,实现用户进程对文件的直接读写,这个任务可以分为以下三步:
## 3.1 寻找连续虚拟地址空间

在用户虚拟地址空间中寻找空闲的满足要求的一段连续的虚拟地址空间,为映射做准备(由内核mmap系统调用完成)。每个进程拥有3G字节的用户虚存空间。但是，这并不意味着用户进程在这3G的范围内可以任意使用，因为虚存空间最终得映射到某个物理存储空间（内存或磁盘空间），才真正可以使用。那么，内核怎样管理每个进程3G的虚存空间呢？概括地说，用户进程经过编译、链接后形成的映象文件有一个代码段和数据段（包括data段和bss段），其中代码段在下，数据段在上。数据段中包括了所有静态分配的数据空间，即全局变量和所有申明为static的局部变量，这些空间是进程所必需的基本要求，这些空间是在建立一个进程的运行映像时就分配好的。除此之外，堆栈使用的空间也属于基本要求，所以也是在建立进程时就分配好的，如下图所示：

![](/kvm_blog/files/kernel/process_virtual_space.png)
 
在内核中,这样每个区域用一个结构struct vm_area_struct 来表示.它描述的是一段连续的、具有相同访问属性的虚存空间，该虚存空间的大小为物理内存页面的整数倍。可以使用 cat /proc/<pid>/maps来查看一个进程的内存使用情况,pid是进程号.其中显示的每一行对应进程的一个vm_area_struct结构.

下面是struct vm_area_struct结构体的定义：
	#include <linux/mm_types.h>
	
	/* This struct defines a memory VMM memory area. */
	
	struct vm_area_struct {
	struct mm_struct * vm_mm; /* VM area parameters */
	unsigned long vm_start;
	unsigned long vm_end;
	
	/* linked list of VM areas per task, sorted by address */
	struct vm_area_struct *vm_next;
	pgprot_t vm_page_prot;
	unsigned long vm_flags;
	
	/* AVL tree of VM areas per task, sorted by address */
	short vm_avl_height;
	struct vm_area_struct * vm_avl_left;
	struct vm_area_struct * vm_avl_right;
	
	/* For areas with an address space and backing store,
	vm_area_struct *vm_next_share;
	struct vm_area_struct **vm_pprev_share;
	struct vm_operations_struct * vm_ops;
	unsigned long vm_pgoff; /* offset in PAGE_SIZE units, *not* PAGE_CACHE_SIZE */
	struct file * vm_file;
	unsigned long vm_raend;
	void * vm_private_data; /* was vm_pte (shared mem) */
	};
      
通常，进程所使用到的虚存空间不连续，且各部分虚存空间的访问属性也可能不同。所以一个进程的虚存空间需要多个vm_area_struct结构来描述。在vm_area_struct结构的数目较少的时候，各个vm_area_struct按照升序排序，以单链表的形式组织数据（通过vm_next指针指向下一个vm_area_struct结构）。但是当vm_area_struct结构的数据较多的时候，仍然采用链表组织的化，势必会影响到它的搜索速度。针对这个问题，vm_area_struct还添加了vm_avl_hight（树高）、vm_avl_left（左子节点）、vm_avl_right（右子节点）三个成员来实现AVL树，以提高vm_area_struct的搜索速度。

假如该vm_area_struct描述的是一个文件映射的虚存空间，成员vm_file便指向被映射的文件的file结构，vm_pgoff是该虚存空间起始地址在vm_file文件里面的文件偏移，单位为物理页面。

![](/kvm_blog/files/kernel/process_vm_struct.png)

因此,mmap系统调用所完成的工作就是准备这样一段虚存空间,并建立vm_area_struct结构体,将其传给具体的设备驱动程序.

## 3.2 建立映射 ##
建立虚拟地址空间和文件或设备的物理地址之间的映射(设备驱动完成)，建立文件映射的第二步就是建立虚拟地址和具体的物理地址之间的映射,这是通过修改进程页表来实现的.mmap方法是file_opeartions结构的成员:

  int (*mmap)(struct file *,struct vm_area_struct *);

linux有2个方法建立页表:

(1) 使用remap_pfn_range一次建立所有页表.  
    
	int remap_pfn_range(struct vm_area_struct *vma, unsigned long virt_addr, unsigned long pfn, unsigned long size, pgprot_t prot); 
	返回值:
	成功返回 0, 失败返回一个负的错误值
	参数说明:
	vma 用户进程创建一个vma区域
	
	virt_addr 重新映射应当开始的用户虚拟地址. 这个函数建立页表为这个虚拟地址范围从 virt_addr 到 virt_addr_size.
	
	pfn 页帧号, 对应虚拟地址应当被映射的物理地址. 这个页帧号简单地是物理地址右移 PAGE_SHIFT 位. 对大部分使用, VMA 结构的 vm_paoff 成员正好包含你需要的值. 这个函数影响物理地址从 (pfn<<PAGE_SHIFT) 到 (pfn<<PAGE_SHIFT)+size.
	
	size 正在被重新映射的区的大小, 以字节.

	prot 给新 VMA 要求的"protection". 驱动可(并且应当)使用在vma->vm_page_prot 中找到的值.

(2) 使用nopage VMA方法每次建立一个页表项.
   
	struct page *(*nopage)(struct vm_area_struct *vma, unsigned long address, int *type);
	返回值:
	成功则返回一个有效映射页,失败返回NULL.
	参数说明:
	address 代表从用户空间传过来的用户空间虚拟地址.
	返回一个有效映射页.

(3) 使用方面的限制：

	remap_pfn_range不能映射常规内存，只存取保留页和在物理内存顶之上的物理地址。因为保留页和在物理内存顶之上的物理地址内存管理系统的各个子模块管理不到。640 KB 和 1MB 是保留页可能映射，设备I/O内存也可以映射。如果想把kmalloc()申请的内存映射到用户空间，则可以通过mem_map_reserve()把相应的内存设置为保留后就可以。

## 3.3 访问实际映射页面

当实际访问新映射的页面时的操作(由缺页中断完成)   
(1)  page cache及swap cache中页面的区分：一个被访问文件的物理页面都驻留在page cache或swap cache中，一个页面的所有信息由struct page来描述。struct page中有一个域为指针mapping ，它指向一个struct address_space类型结构。page cache或swap cache中的所有页面就是根据address_space结构以及一个偏移量来区分的。
 
(2) 文件与 address_space结构的对应：一个具体的文件在打开后，内核会在内存中为之建立一个struct inode结构，其中的i_mapping域指向一个address_space结构。这样，一个文件就对应一个address_space结构，一个 address_space与一个偏移量能够确定一个page cache 或swap cache中的一个页面。因此，当要寻址某个数据时，很容易根据给定的文件及数据在文件内的偏移量而找到相应的页面。 
(3) 进程调用mmap()时，只是在进程空间内新增了一块相应大小的缓冲区，并设置了相应的访问标识，但并没有建立进程空间到物理页面的映射。因此，第一次访问该空间时，会引发一个缺页异常。 

(4) 对于共享内存映射情况，缺页异常处理程序首先在swap cache中寻找目标页（符合address_space以及偏移量的物理页），如果找到，则直接返回地址；如果没有找到，则判断该页是否在交换区 (swap area)，如果在，则执行一个换入操作；如果上述两种情况都不满足，处理程序将分配新的物理页面，并把它插入到page cache中。进程最终将更新进程页表。 
     
注：对于映射普通文件情况（非共享映射），缺页异常处理程序首先会在page cache中根据address_space以及数据偏移量寻找相应的页面。如果没有找到，则说明文件数据还没有读入内存，处理程序会从磁盘读入相应的页面，并返回相应地址，同时，进程页表也会更新.

(5) 所有进程在映射同一个共享内存区域时，情况都一样，在建立线性地址与物理地址之间的映射之后，不论进程各自的返回地址如何，实际访问的必然是同一个共享内存区域对应的物理页面。

 
# 参考资料 #

1、http://fengtong.iteye.com/blog/457090  
2、http://blog.chinaunix.net/space.php?uid=24704319&do=blog&cuid=2344951  
3、http://www.rosoo.net/a/201002/8464.html