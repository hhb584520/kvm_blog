#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>

atomic_t stop_mmio;
static int mmio_test_init(void)
{
	int a;
	
	atomic_set(&stop_mmio, 1);
	a = atomic_read(&stop_mmio);

	printk(KERN_INFO "a=%d\n", a);
	atomic_set(&stop_mmio, -1);	
	return 0;
}

static void mmio_test_exit(void)
{
	printk(KERN_INFO "mmio_exit: mmio test module, bye.\n");
}

module_init(atomic_test_init);
module_exit(atomic_test_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("Atomic read/write test program.");
