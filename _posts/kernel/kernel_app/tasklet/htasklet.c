#include <linux/module.h> 
#include <linux/init.h> 
#include <linux/interrupt.h> 
 
static void my_tasklet_handler(unsigned long flag); 
DECLARE_TASKLET(my_tasklet, my_tasklet_handler, 0); 
 
static void my_tasklet_handler(unsigned long flag) 
{ 
 	printk("my_tasklet run: do what the tasklet want to do....\n"); 
} 
 
static int htasklet_init(void) 
{ 
 	printk("module init start. \n"); 
 	printk("Hello tasklet!\n"); 
 	tasklet_schedule(&my_tasklet); 
 	printk("module init end.\n"); 
 	return 0; 
} 

static void htasklet_exit(void) 
{ 
 	tasklet_kill(&my_tasklet); 
 	printk("Goodbye, tasklet!\n"); 
} 
  
module_init(htasklet_init);
module_exit(htasklet_exit);
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haibin Huang");
MODULE_DESCRIPTION("kernel work queue examples.");
