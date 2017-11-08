#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>

#define RD_FLAG 1
#define WR_FLAG 2

static int rw_flag = 3;
static long addr = 0x0;

module_param(addr, long, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(addr, "physical addr: lspci -vv -s $bdf ");
module_param(rw_flag, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(rw_flag, "write=2 and read=1");

static int *mmio_virt_addr;
atomic_t stop_mmio;
static int mmio_test_init(void)
{
	int i;
	atomic_set(&stop_mmio, 1);

	while(atomic_read(&stop_mmio)){
		printk(KERN_INFO "mmio_init: mmio test module, start.\n");
		if(addr == 0x0)
		{
			printk(KERN_INFO "please give right addr!\n");
			return 0;
		}
		mmio_virt_addr = ioremap(addr, 4096);
		printk(KERN_INFO "phy_addr=%lx, mmio_virt_addr = 0x%lx\n", addr, (unsigned long)mmio_virt_addr);

		if((rw_flag & WR_FLAG) && (rw_flag & RD_FLAG))
		{
			printk(KERN_INFO "read & write\n");
			for(i=0; i < 4; i+=4)
			{
				mmio_virt_addr[i]=789;
				printk(KERN_INFO "mmio_virt_addr[%d]=%d\n", i, mmio_virt_addr[i]);
			}
		}
		
		else if(rw_flag & WR_FLAG)
		{
			printk(KERN_INFO "write only\n");
			for(i=0; i < 4; i+=4)
			{
				mmio_virt_addr[i]=789;
			}
		}
		else if(rw_flag & RD_FLAG)
		{
			printk(KERN_INFO "read only\n");
			for(i=0; i < 4; i+=4)
			{
				printk(KERN_INFO "mmio_virt_addr[%d]=%d\n", i, mmio_virt_addr[i]);
			}
		}
	}

	atomic_set(&stop_mmio, -1);	
	return 0;
}

static void mmio_test_exit(void)
{
    atomic_set(&stop_mmio, 0);

	while(atomic_read(&stop_mmio) != -1)
		cpu_relax();
	if(addr == 0x0)
	{
		printk(KERN_INFO "please give right addr!\n");
		return ;
	}
	iounmap(mmio_virt_addr);
	printk(KERN_INFO "mmio_exit: mmio test module, bye.\n");
}

module_init(mmio_test_init);
module_exit(mmio_test_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("MMIO read/write test program.");
