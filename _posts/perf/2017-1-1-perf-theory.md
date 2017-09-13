
# 1.测试优化概述 #
## 1.1 性能指标 ##

性能指标最好以数值的形式来体现，如下表所示
- 场景
- 理想(ms)
- 下限(ms)
- 优化前(ms)
- 优化后(ms)
- 提升（倍）

## 1.2 测试工具 ##
测试工具是十分重要，影响到测试结果的准确性以及性能瓶颈定位。
测试工具要符合以下几点：

- 支持输出函数调用关系图
- 支持输出函数被调用的次数
- 支持输出调用函数的时间占所有时间的百分比
- 支持统计库函数

下面这些是可选的，有这些功能更好。

- 支持分析cache命中率
- 支持源码级分析
- 支持汇编级分析

## 1.3 测试优化基本流程 ##

![](/kvm_blog/files/perf/perf_flow.png)

## 1.4 测试优化基础知识 ##
程序性能的问题，有很多原因，总结如下三点：

- 程序的运算量很大，导致 CPU过于繁忙，CPU是瓶颈。
- 程序需要做大量的 I/O，读写文件、内存操作等等，CPU 更多的是处于等待，I/O部分称为程序性能的瓶颈。
- 程序之间相互等待，结果 CPU 利用率很低，但运行速度依然很慢，事务间的共享与死锁制约了程序的性能。

## 1.5 top-down ##
http://zhaozhanxu.com/2017/02/03/SDN/OVS/2017-02-03-analyzing-bottlenecks/

# 参考资料 #

《嵌入式Linux性能详解》，史子旺  
https://perf.wiki.kernel.org/index.php/Main_Page，perf主页  
http://www.docin.com/p-619608212.html，Linux 的系统级性能剖析工具-perf （一） - 淘宝内核组  
http://www.ibm.com/developerworks/cn/linux/l-cn-perf1/，Perf -- Linux下的系统性能调优工具，第 1 部分  