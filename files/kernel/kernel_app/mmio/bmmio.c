#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/delay.h>
#include <linux/kthread.h>
#include <linux/sched.h>

#define RD_FLAG 1
#define WR_FLAG 2

static int rw_flag = 3;
static long addr = 0x0;

module_param(addr, long, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(addr, "physical addr: lspci -vv -s $bdf ");
module_param(rw_flag, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
MODULE_PARM_DESC(rw_flag, "write=2 and read=1");

static int *mmio_virt_addr;
static struct task_struct *rd_thread;
static struct task_struct *wr_thread;

int rd_fn(void *arg)
{
    int i=0;
    int count=0;

    printk(KERN_INFO "read thread\n");
    while(kthread_should_stop() == 0)
    {
        for(i=0; i < 4; i+=4)
        {
            printk(KERN_INFO "read: mmio_virt_addr[%d]=%d\n", i, mmio_virt_addr[i]);
        }

        count++;
        if(count>1000)
        {
            msleep(1);
            count=0;
        }
    }

    return 0;
}

int wr_fn(void *arg)
{    
    int i=0;
    int count=0;

    printk(KERN_INFO "Write thread\n");
    while(kthread_should_stop() == 0)
    {
        printk(KERN_INFO "write 789\n");
        for(i=0; i < 4; i+=4)
        {
            mmio_virt_addr[i]=789;
        }
        count++;
        if(count>1000)
        {
            msleep(1);
            count=0;
        }
    }

    return 0;
}

static int mmio_test_init(void)
{
    if(addr == 0x0)
    {
        printk(KERN_INFO "please give right addr!\n");
        return 0;
    }
	
    mmio_virt_addr = ioremap(addr, 4096);
    printk(KERN_INFO "phy_addr=%lx, mmio_virt_addr = 0x%lx\n", addr, (unsigned long)mmio_virt_addr);
		
    printk(KERN_INFO "mmio_init: create thread...\n");
    if(rw_flag & RD_FLAG)
    {
        rd_thread = kthread_create(rd_fn, NULL, "read_mmio_thread");
        if(rd_thread)
        {
            printk(KERN_INFO "Waking up read mmio thread...\n");
            wake_up_process(rd_thread);
        }
    }
	
    if(rw_flag & WR_FLAG)
    {
        wr_thread = kthread_create(wr_fn, NULL, "write_mmio_thread");
        if(wr_thread)
        {
            printk(KERN_INFO "Waking up write mmio thread...\n");
            wake_up_process(wr_thread);
        }
    }

    return 0;
}

static void mmio_test_exit(void)
{
    int ret = 0;
    printk(KERN_INFO "mmio_exit: mmio test module, bye.\n");
	
    if(addr == 0x0)
    {
        printk(KERN_INFO "please give right addr!\n");
        return ;
    }

    if(rw_flag & RD_FLAG)
    {
        ret = kthread_stop(rd_thread);
        if(!ret)
        {
            printk(KERN_INFO "Read thread stopped\n");
        }
    }

    	
    if(rw_flag & WR_FLAG)
    {
        ret = kthread_stop(wr_thread);
        if(!ret)
        {
            printk(KERN_INFO "Write thread stopped\n");
        }
    }
}

module_init(mmio_test_init);
module_exit(mmio_test_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("MMIO read/write test program.");
