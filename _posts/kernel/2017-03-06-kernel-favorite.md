## copy_from_user ##
最近貌似有人问为什么要用copy_from_user这类函数的问题，难道内核不能使用用户态的指针吗？那人自己做了个实验，不用copy_from_user，而是直接在内核里使用用户态指针，程序运行得好好的，啥事也没有。那么内核干嘛还要提供这么些函数呢？

我看网上有人说用户态指针在内核里没有意义了，如同内核指针在用户态一样没有意义了。这话其实不对，以x86来说，页目录表是放在CR3中的，这个寄存器 没有什么内核态用户态之分，换句话说一个用户态进程通过系统调用进入内核态，task_struct结构中的cr3都是不变的，没有页目录表变化的情况发 生。所以内核态使用用户进程传递过来的指针是有意义的，而且在用户态下内核的指针也是有意义的，只不过因为权限不够，用户进程使用内核指针就有异常发生。 

回到上面的话题，既然内核可以使用用户进程传递过来的指针，那干吗不使用memcpy呢？绝大多数情况下使用memcpy取代 copy_from_user都是OK的，事实上在没有MMU的体系上，copy_from_user就是memcpy。但是为什么有MMU就不一样了 呢，使用copy_from_user除了那个access_ok检查之外，它的实现前半部分就是memcpy，后边多了个两个section。这话要得 从内核提供的缺页异常说起，而且copy_from_user就是用来对付用户态的指针所指向的虚拟地址没有映射到实际物理内存这种情况，这个现象在用户 空间不是什么大事，缺页异常会自动提交物理内存，之后发生异常的指令正常运行，彷佛啥事也没发生。但是这事放到内核里就不一样了，内核需要显式地去修正这 个异常，背后的思想是：内核对于没有提交物理地址的虚拟地址空间的访问不能象用户进程那样若无其事，内核得表明下态度--别想干坏事，老子盯着你呢。就这 么个意思。所以copy_from_user和memcpy的区别就是多了两个section，这样对于缺页的异常，copy_from_user可以修 正，但是memcpy不行。 

我后来想能不能想个办法验证一下，在网上看到有人说用户空间的malloc是先分配虚拟空间，用到的时候才映射物理地址。这正好满足我们的要求，结果不是 很理想，我不知道这个malloc到底内核是不是有类似copy-on-write这样大的特性，总之memcpy对这种情况没有报任何异常。那就干脆来 狠的，直接估摸着一个可能还没被映射的用户空间的虚地址，传递给了内核空间的驱动程序，于是问题来了：memcpy发生了 oops，copy_from_user正常运行了。 

看来两者之间就这点区别了，至于access_ok，看过源码的人都知道那不过是验证一下地址范围而已，我开始还以为这个函数会操作页目录表，事实上完全不是。

##ipc##
https://www.ibm.com/developerworks/cn/linux/l-ipc/