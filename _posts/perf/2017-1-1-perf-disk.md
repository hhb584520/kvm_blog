IOPS，即I/O per second，即每秒读写（I/O）操作的次数，多用于OLTP/数据库、小文件存储等场合，衡量随机访问的性能。



# IOPS的测试benchmark工具 #

IOPS的测试benchmark工具主要有Iometer, IoZone, FIO等，可以综合用于测试磁盘在不同情形下的IOPS。对于应用系统，需要首先确定数据的负载特征，然后选择合理的IOPS指标进行测量和对比分析，据此选择合适的存储介质和软件系统。

# 参考资料 #

http://elf8848.iteye.com/blog/1731274

http://elf8848.iteye.com/blog/1731301