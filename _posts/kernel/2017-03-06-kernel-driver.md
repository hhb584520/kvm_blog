﻿
## 1. 设备驱动的分类 ##

计算机系统的主要硬件由CPU、存储器和外部设备组成。驱动程序的对象一般是存储器和外部设备。随着芯片制造工艺的提高，为了节约成本，通常将很多原属于外部设备的控制器嵌入到CPU内部。所以现在的驱动程序应该支持CPU中的嵌入控制器。Linux将这些设备分为3大类：字符设备、块设备、网络设备。

## 2. probe 函数 ##

linux中 probe函数何时调用的
         
所以的驱动教程上都说：只有设备和驱动的名字匹配，BUS就会调用驱动的probe函数，但是有时我们要看看probe函数里面到底做了什么，还有传递给 probe函数的参数我们就不知道在哪定义（反正不是我们在驱动里定义的），如果不知道传递进的参数，去看probe函数总是感觉不求甚解的样子（你对系 统不求甚解，系统也会对你的要求不求甚解的），心里对自己写出的程序没底，保不齐那天来个bug，就悲剧了。

这里以static int__devinit sst25l_probe(struct spi_device *spi)为例看看传递进的参数structspi_device *spi到底是什么，在哪定义，什么时候定义，定义了有什么用…？（本着“five W and H”的原则打破沙锅问到底）。首先struct spi_device *spi不是我们定义的驱动里定义的；其次在read，write等函数里都有struct spi_device *spi的影子，不过不是直接传递进去的，而是通过传递进去struct mtd_info *mtd，然后to_sst25l_flash(mtd)，即container_of()出包含mtd的struct sst25l_flash *flash，其中flash里的第一个成员就是structspi_device *spi，而此成员的赋值就是将传递给probe中的struct spi_device *spi赋值给struct sst25l_flash *flash的，有代码为证：

	static int __devinit sst25l_probe(structspi_device *spi)
	{
         structflash_info *flash_info;
         structsst25l_flash *flash;
         ……
         flash->spi = spi;// 将structspi_device *spi赋值给struct sst25l_flash *flash
         mutex_init(&flash->lock);
         dev_set_drvdata(&spi->dev,flash);// &spi->dev ->p->driver_data = flash保持flash
         ……
	}

所以搞清楚structspi_device *spi的来源是搞清楚设备驱动与主控驱动的联系纽带的关键之一，当然要首先搞清楚probe函数什么时候调用才能搞清楚struct spi_device *spi怎么传递的，其重要性不言而喻（虽然言了很多，^-^，有点唐僧了）。我们先从驱动的init开始入手，毕竟这是驱动注册开始的地方，也是一系列 后续操作引发的地方：

	static int __init sst25l_init(void)
	{
	     returnspi_register_driver(&sst25l_driver);
	}

里面只有一个函数，最喜欢这样的函数了：

	int spi_register_driver(struct spi_driver*sdrv)
	{
	     sdrv->driver.bus= &spi_bus_type;
	     if(sdrv->probe)
	               sdrv->driver.probe= spi_drv_probe;
	     if(sdrv->remove)
	               sdrv->driver.remove= spi_drv_remove;
	     if(sdrv->shutdown)
	               sdrv->driver.shutdown= spi_drv_shutdown;
	     return driver_register(&sdrv->driver);
	}

前面都是赋值，直接最后一个语句：

	int driver_register(struct device_driver*drv)
	{
	     intret;
	     structdevice_driver *other;
	     ……
	     ret = bus_add_driver(drv);
	     if(ret)
	               returnret;
	     ret= driver_add_groups(drv, drv->groups);
	     if(ret)
	               bus_remove_driver(drv);
	     returnret;
	}

bus_add_driver(drv)看着就像“好人”：

	int bus_add_driver(struct device_driver*drv)
	{
	     structbus_type *bus;
	     structdriver_private *priv;
	     interror = 0;
	     ……
	     if(drv->bus->p->drivers_autoprobe) {
	               error= driver_attach(drv);
	               if(error)
	                        goto out_unregister;
	     }
	     ……
	}
         
driver_attach看着也很“友善”（函数名中带get，init的一般都不是，如果里面有几个“友善”的，一首歌中已经告诉了我们解决的办 法：“xx就像偶尔拨不通的电话号码，多试几次总会回答，……”，如果网上找不到，只好挨个跟踪了，我就这样找的，笨人只好采取笨办法，也是没有办法的办 法了）：

	int driver_attach(struct device_driver*drv)
	{
	     returnbus_for_each_dev(drv->bus, NULL, drv, __driver_attach);
	}
         
里面只有一个函数，goon：

	int bus_for_each_dev(struct bus_type *bus,struct device *start, void *data, int (*fn)(struct device *, void *))
	{
	     structklist_iter i;
	     structdevice *dev;
	     interror = 0;
	    
	     if(!bus)
	              return -EINVAL;
	    
	     klist_iter_init_node(&bus->p->klist_devices,&i, (start ? &start->p->knode_bus : NULL));
	     while((dev = next_device(&i)) && !error)
	              error = fn(dev,data);
	     klist_iter_exit(&i);
	     returnerror;
	}
         
看到这里好像没有我们想要找的attach，只执行了个fn()函数，肿么回事？到回头看看哪里漏了，在bus_for_each_dev中传递了个 __driver_attach，也就是在bus_for_each_dev执行了__driver_attach(dev, data)，那么它里面到底执行了什么？

	static int __driver_attach(struct device*dev, void *data)
	{
	     structdevice_driver *drv = data;
	    
	     if (!driver_match_device(drv, dev))
	              return 0;
	    
	     if(dev->parent)/* Needed for USB */
	               device_lock(dev->parent);
	     device_lock(dev);
	     if(!dev->driver)
	               driver_probe_device(drv, dev);
	     device_unlock(dev);
	     if(dev->parent)
	               device_unlock(dev->parent);
	    
	     return0;
	}
         
有个driver_probe_device(drv,dev)，继续跟踪：

	int driver_probe_device(structdevice_driver *drv, struct device *dev)
	{
	     intret = 0;
	     ……
	     ret = really_probe(dev, drv);
	     pm_runtime_put_sync(dev);
	
	     returnret;
	}
         
有个really_probe(dev,drv)，linux神马的就喜欢这样，经常一个函数传递给另一函数，后一个函数就是在前一个函数前加“do_”、“really_”、“__”，还经常的就是宏定义的或inline的。

	static int really_probe(struct device *dev,struct device_driver *drv)
	{
	     intret = 0;
	     ……
	     if(dev->bus->probe) {
	               ret = dev->bus->probe(dev);
	               if(ret)
	                        gotoprobe_failed;
	     }else if (drv->probe) {
	               ret = drv->probe(dev);
	               if(ret)
	                        gotoprobe_failed;
	     }
	     ……
	     returnret;
	}
         
这里如果有总线上的probe函数就调用总线的probe函数，如果没有则调用drv的probe函数。在static int__driver_attach(struct device *dev, void *data)中先调用了driver_match_device(drv,dev)，用于匹配，成功才继续执行，否则直接返回了。 driver_match_device(drv, dev)中：

	static inline intdriver_match_device(struct device_driver *drv,
	                                       struct device *dev)
	{
	     returndrv->bus->match ? drv->bus->match(dev, drv) : 1;
	}
         
即如果match函数的指针不为空，则执行此bus的match函数，也就是为什么资料上老是说总线负责匹配设备和驱动了。这里也传递了参数struct device *dev，到底这个dev来自何方，会在下一篇文章中继续跟踪。

 本文章参考：http://blog.chinaunix.net/space.php?uid=15887868&do=blog&id=2758294，对原作者表示感谢！

## 参考资料 ##
http://blog.chinaunix.net/uid-24512513-id-3187337.html
http://blog.chinaunix.net/uid-26921272-id-3422993.html

http://blog.csdn.net/tommy_wxie/article/details/17003997

blog.csdn.net/xiafeng1113/article/details/8030248