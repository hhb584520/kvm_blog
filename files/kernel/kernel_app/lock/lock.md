## 中断上下文加锁
使用 tasklet 的一个好处在于，它自己负责执行的序列化保障：两个相同类型的 tasklet 不允许同时执行，即使在不同的处理器上也不行。这意味着你无须为 intra-tasklet 的同步问题操心了。tasklet 之间的同步需要正确使用锁机制：

如果进程上下文和一个下半部共享数据，在访问这些数据之前，你需要禁止下半部的处理并得到锁的的使用权。做这些是为了本地和SMP的保护并且防止死锁的出现。

local_bh_disable
local_bh_enable

如果中断上下文和一个下半部共享数据，在访问这些数据之前，你需要禁止中断并得到锁的的使用权。所做这些是为了本地和SMP的保护并且防止死锁的出现。

local_irq_disable
local_irq_enable

## mutex 和 spin_lock

Please see vfio_pci.c and vfio_pci_intrs.c
 
	mutex_init
	spin_lock_init
	
	mutex_lock
	mutex_unlock
	
	spin_lock
	spin_unlock

## 原子操作

参考 hatomic.c