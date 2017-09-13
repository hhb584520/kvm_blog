# 1. char dev

we can reference kernel vfio_init
## 1.1 class_create

	
	class_create动态创建设备的逻辑类，并完成部分字段的初始化，然后将其添加到内核中。创建的逻辑类位于/sys/class/。
	参数：
	     owner, 拥有者。一般赋值为THIS_MODULE。
	     name, 创建的逻辑类的名称。

## 1.2 alloc_chrdev_region
register a range of char device numbers

Name

	alloc_chrdev_region — register a range of char device numbers 

Synopsis

	int alloc_chrdev_region ( dev_t * dev,  
	  unsigned baseminor,  
	  unsigned count,  
	  const char * name); 

Arguments

	dev_t * dev
	output parameter for first assigned number 
	unsigned baseminor
	first of the requested range of minor numbers 
	unsigned count
	the number of minor numbers required 
	const char * name
	the name of the associated device or driver
 