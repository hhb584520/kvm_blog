# Modules

## 1. 参考介绍
http://www.tldp.org/LDP/lkmpg/2.6/html/index.html

## 2. 错误解决
	[root@localhost 4.11.0-rc3]# ll
	total 2896
	lrwxrwxrwx  1 root root     31 Jul 11 16:07 **build -> /workspace/BUILD/kvm-4.11.0_rc3**
	drwxr-xr-x 12 root root   4096 Jul 11 16:08 kernel
	-rw-r--r--  1 root root 777107 Apr 26 17:12 modules.alias
	......
	-rw-r--r--  1 root root 423990 Apr 26 17:12 modules.symbols.bin
	lrwxrwxrwx  1 root root     31 Jul 11 16:08 source -> /workspace/BUILD/kvm-4.11.0_rc3

	$ ln -sf /haibin/linux-stable/ build
	$ ln -sf /haibin/linux-stable/ source
	$ cd /haibin/hmmio
	$ ls
		bmmio.c  Makefile
	$ make
		make -C /lib/modules/4.11.0-rc3/build M=/haibin/hmmio modules
		make[1]: Entering directory `/haibin/linux-stable'
		
		  ERROR: Kernel configuration is invalid.
		         include/generated/autoconf.h or include/config/auto.conf are missing.
		         Run 'make oldconfig && make prepare' on kernel src to fix it.	
		
		  WARNING: Symbol version dump ./Module.symvers
		           is missing; modules will have no dependencies and modversions.
		
		  Building modules, stage 2.
		scripts/Makefile.modpost:42: include/config/auto.conf: No such file or directory
		make[2]: *** No rule to make target `include/config/auto.conf'.  Stop.
		make[1]: *** [modules] Error 2
		make[1]: Leaving directory `/haibin/linux-stable'
		make: *** [all] Error 2

	$ cp /boot/config-4.11.0-rc3 /haibin/linux-stable/.config
	$ cd /haibin/linux-stable/
	$ make oldconfig && make prepare
		HOSTCC  scripts/basic/fixdep
		HOSTCC  scripts/kconfig/conf.o
		SHIPPED scripts/kconfig/zconf.tab.c
		......
	$ make modules_prepare
		CHK     include/config/kernel.release
		CHK     include/generated/uapi/linux/version.h
		CHK     include/generated/utsrelease.h
		......
	$ cd /haibin/hmmio
	$ make
		make -C /lib/modules/4.11.0-rc3/build M=/haibin/hmmio modules
		make[1]: Entering directory `/haibin/linux-stable'
		
		  WARNING: Symbol version dump ./Module.symvers
		           is missing; modules will have no dependencies and modversions.
		
		  CC [M]  /haibin/hmmio/bmmio.o
		  Building modules, stage 2.
		  MODPOST 1 modules
		  CC      /haibin/hmmio/bmmio.mod.o
		  LD [M]  /haibin/hmmio/bmmio.ko
		make[1]: Leaving directory `/haibin/linux-stable'


## 3. 例子

例子 Makefile

	Example 2-4. Makefile for both our modules
	
	obj-m += hello-1.o
	obj-m += hello-2.o
	
	all:
		make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
	
	clean:
		make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

例子程序

	/*
	 *  hello-5.c - Demonstrates command line argument passing to a module.
	 */

	#include <linux/module.h>
	#include <linux/moduleparam.h>
	#include <linux/kernel.h>
	#include <linux/init.h>
	#include <linux/stat.h>
	
	MODULE_LICENSE("GPL");
	MODULE_AUTHOR("Peter Jay Salzman");
	
	static short int myshort = 1;
	static int myint = 420;
	static long int mylong = 9999;
	static char *mystring = "blah";
	static int myintArray[2] = { -1, -1 };
	static int arr_argc = 0;
	
	/* 
	 * module_param(foo, int, 0000)
	 * The first param is the parameters name
	 * The second param is it's data type
	 * The final argument is the permissions bits, 
	 * for exposing parameters in sysfs (if non-zero) at a later stage.
	 */
	
	module_param(myshort, short, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP);
	MODULE_PARM_DESC(myshort, "A short integer");
	module_param(myint, int, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	MODULE_PARM_DESC(myint, "An integer");
	module_param(mylong, long, S_IRUSR);
	MODULE_PARM_DESC(mylong, "A long integer");
	module_param(mystring, charp, 0000);
	MODULE_PARM_DESC(mystring, "A character string");
	
	/*
	 * module_param_array(name, type, num, perm);
	 * The first param is the parameter's (in this case the array's) name
	 * The second param is the data type of the elements of the array
	 * The third argument is a pointer to the variable that will store the number 
	 * of elements of the array initialized by the user at module loading time
	 * The fourth argument is the permission bits
	 */
	module_param_array(myintArray, int, &arr_argc, 0000);
	MODULE_PARM_DESC(myintArray, "An array of integers");
	
	static int __init hello_5_init(void)
	{
		int i;
		printk(KERN_INFO "Hello, world 5\n=============\n");
		printk(KERN_INFO "myshort is a short integer: %hd\n", myshort);
		printk(KERN_INFO "myint is an integer: %d\n", myint);
		printk(KERN_INFO "mylong is a long integer: %ld\n", mylong);
		printk(KERN_INFO "mystring is a string: %s\n", mystring);
		for (i = 0; i < (sizeof myintArray / sizeof (int)); i++)
		{
			printk(KERN_INFO "myintArray[%d] = %d\n", i, myintArray[i]);
		}
		printk(KERN_INFO "got %d arguments for myintArray.\n", arr_argc);
		return 0;
	}
	
	static void __exit hello_5_exit(void)
	{
		printk(KERN_INFO "Goodbye, world 5\n");
	}
	
	module_init(hello_5_init);
	module_exit(hello_5_exit);
	I would recommend playing around with this code:
	
	satan# insmod hello-5.ko mystring="bebop" mybyte=255 myintArray=-1
	mybyte is an 8 bit integer: 255
	myshort is a short integer: 1
	myint is an integer: 20
	mylong is a long integer: 9999
	mystring is a string: bebop
	myintArray is -1 and 420
	
	satan# rmmod hello-5
	Goodbye, world 5
	
	satan# insmod hello-5.ko mystring="supercalifragilisticexpialidocious" \
	> mybyte=256 myintArray=-1,-1
	mybyte is an 8 bit integer: 0
	myshort is a short integer: 1
	myint is an integer: 20
	mylong is a long integer: 9999
	mystring is a string: supercalifragilisticexpialidocious
	myintArray is -1 and -1
	
	satan# rmmod hello-5
	Goodbye, world 5
	
	satan# insmod hello-5.ko mylong=hello
	hello-5.o: invalid argument syntax for mylong: 'h'