# 通过字符设备传递命令和参数 #

## 用户态 ##

/* 设置 LED灯的状态 */

	#define PDC_MISC_IOCSET_LED _IOWR(PDC_MISC_BASE_CMD, 0u, Ptr);
	
	Int32  PDI_miscIoctl(Uint32 cmd, Ptr pCmdArgs)
	{
	        MISC_Obj        *pMiscObj;
	        
	        int miscFd = open("/dev/pdcMisc", O_RDWR);
	        ioctl(miscFd, PDC_MISC_IOCSET_LED, pCmdArgs);
	}

## 内核态 ##
谁来调用 MISC_ioctl
insmod PDC_drvInit

### 1. 创建字符设备 ###

    static struct file_operations gFops = {
            .owner        = THIS_MODULE,
            .ioctl            = MISC_ioctl;
            .open            = MISC_open;
    };
    // 主次设备号都为 0， 则自动分配设备号
    alloc_chrdev_region(&devNo, 0, 1, cDevName);
    register_chrdev_region(devNo, 1, cDevName);
    cdev_init(&pCdevObj->cdev, &gFops);
    cdev_add(&pCdevObj->cdev, pCdevObj->devNo, 1);
    struct class pClass = class_create(THIS_MODULE, pCdevObj->name);
    struct class_device pClassDevice = device_create (pClass, NULL, devNo, NULL, cDevName);

### 2. 调用系统调用 ###

	static Int32 MISC_ioctl(OSA_KCdevHandle hCdev, Uint32 cmd, Uint32L arg)
	{
	    switch (cmd)
	    {
            case PDC_MISC_IOCSET_LED:
                    PDC_ledSetParams ledParams;
                    status = copy_from_user(&ledParams, (Ptr)arg, sizeof(ledParams));
                    break;
	    }
	}
        
