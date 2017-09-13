#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

atomic_t stop_mmio;
static int hatomic_init(void)
{
	int i;
	atomic_set(&stop_mmio, 1);

	while(atomic_read(&stop_mmio)){
		printk(KERN_INFO "hatomic_init: atomic test module, start.\n");
		break;
	}

	atomic_set(&stop_mmio, -1);	
	return 0;
}

static void hatomic_exit(void)
{
    atomic_set(&stop_mmio, 0);
	while(atomic_read(&stop_mmio) != -1)
		cpu_relax();

	printk(KERN_INFO "hatomic_exit: atomic test module, bye.\n");
}

module_init(hatomic_init);
module_exit(hatomic_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("atomic read/write test program.");
