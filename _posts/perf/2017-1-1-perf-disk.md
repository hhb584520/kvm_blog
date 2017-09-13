io benchmark 总体介绍

http://blog.cloudharmony.com/2010/06/disk-io-benchmarking-in-cloud.html

http://www.slashroot.in/linux-file-system-read-write-performance-test

https://www.jamescoyle.net/how-to/913-simple-bonnie-example

# 1.IOPS的测试benchmark工具 #

IOPS，即I/O per second，即每秒读写（I/O）操作的次数，多用于OLTP/数据库、小文件存储等场合，衡量随机访问的性能。

IOPS的测试benchmark工具主要有Iometer, IoZone, FIO等，可以综合用于测试磁盘在不同情形下的IOPS。对于应用系统，需要首先确定数据的负载特征，然后选择合理的IOPS指标进行测量和对比分析，据此选择合适的存储介质和软件系统。


# 2.硬盘测试
## 2.1 hdparm
### 2.1.1 install

	yum install hdparm -y

### 2.1.2 usage

http://www.ha97.com/4963.html

**测试速率**

	hdparm -tT /dev/sda

**显示硬盘的相关设置**

	[root@oracle ~]# hdparm /dev/sda
	/dev/sda:
	IO_support = 0 (default 16-bit)
	readonly = 0 (off)
	readahead = 256 (on)
	geometry = 19929［柱面数］/255［磁头数］/63［扇区数］, sectors = 320173056［总扇区数］, start = 0［起始扇区数］

## 2.2 fio

Fio 是个强大的IO压力测试工具。随着块设备的发展，特别是SSD盘的出现，设备的并行度越来越高。利用好这些设备，有个诀窍就是提高设备的iodepth, 一把提交给设备更多的IO请求，让电梯算法和设备有机会来安排合并以及内部并行处理，提高总体效率。

应用使用IO通常有二种方式：同步和异步。 同步的IO一次只能发出一个IO请求，等待内核完成才返回，这样对于单个线程iodepth总是小于1，但是可以透过多个线程并发执行来解决，通常我们会用16-32根线程同时工作把iodepth塞满。 异步的话就是用类似libaio这样的linux native aio一次提交一批，然后等待一批的完成，减少交互的次数，会更有效率。

### 2.2.1 参数解析

- filename=/dev/sdb1 测试文件名称，通常选择需要测试的盘的data目录。 可以通过冒号分割同时指定多个文件，filename=/dev/sda:/dev/sdb
- direct=1 测试过程绕过机器自带的buffer。使测试结果更真实。 
- bs=16k 单次io的块文件大小为16k，默认是 4k
- bsrange=512-2048 同上，提定数据块的大小范围 
- size=5g 本次的测试文件大小为5g，以每次4k的io进行测试。 
- numjobs=30 本次的测试线程为30. 
- runtime=1000 测试时间为1000秒，如果不写则一直将5g文件分4k每次写完为止。 
- rwmixwrite=30 在混合读写的模式下，写占30%  
- lockmem=1g 只使用1g内存进行测试。 
- zero_buffers 用0初始化系统buffer。 
- nrfiles=8 每个进程生成文件的数量。 
- directory: 设置filename的路径前缀。在后面的基准测试中，采用这种方式来指定设备。
- name: 指定job的名字，在命令行中表示新启动一个job。
- ioengine: I/O引擎，现在fio支持19种ioengine。默认值是sync同步阻塞I/O，libaio是Linux的native异步I/O，要结合 direct=1 使用。关于同步异步，阻塞和非阻塞模型可以参考文章“使用异步 I/O 大大提高应用程序的性能” http://www.ibm.com/developerworks/cn/linux/l-async/
- iodepth: 如果ioengine采用异步方式，该参数表示一批提交保持的io单元数。该参数可参考文章“Fio压测工具和io队列深度理解和误区”。http://blog.yufeng.info/archives/2104
- rw: I/O模式，随机读写，顺序读写等等。
- time_based: 如果在runtime指定的时间还没到时文件就被读写完成，将继续重复知道runtime时间结束。
- group_reporting: 当同时指定了numjobs了时，输出结果按组显示。

### 2.2.2 实际例子

**命令行**

	$ fio -filename=/dev/sda -direct=1 -iodepth 1 -thread -rw=read -ioengine=psync -bs=16k -size=200G -numjobs=30 -runtime=1000 -group_reporting -name=mytest
	
	
**文件**

	cat random-read-test.fio
	[random-read]
	rw=randread
	size=128m
	directory=/fio-testing/data
	
	￥fio random-read-test.fio

## 2.3 iostat
tps：该设备每秒的传输次数，表示每秒多少个I/O请求

Blk_read/s：每秒从设备读取到的数据量

Blk_wrtn/s：每秒向设备写入的数据量

Blk_read：读取的总数据量

Blk_wrtn：写入的总数据量

%user：代表用户态进程使用CPU的负载

%nice：代表优先级进程使用的CPU负载

%system：代表内核态进程使用的CPU负载

%iowait：代表CPU等待I/O时，CPU的负载

%steal：代表被偷走的CPU负载情况，这个在虚拟化技术中会用到

%idle：代表空闲的所占用的CPU负载情况

iostat还有一个常用的参数选项-x，表示扩展的信息
rrqm/s：每秒这个设备相关的读取请求有多少被Merge(多个I/O合并的操作)了

wrqm/s：每秒这个设备相关的写入请求有多少被Merge了

r/s：每秒发送到设备的读请求数

w/s：每秒发送到设备的写请求数

rsec/s：每秒读取设备扇区的次数

wsec/s：每秒写入设备扇区的次数

avgrq-sz：平均请求扇区的大小

avgqu-sz：平均请求队列的长度

await：每一个I/O请求的处理的平均时间(等待时间)

r_await：每一个读I/O请求的处理的平均时间

w_await：每一个写I/O请求的处理的平均时间

svctm：表示平均每次I/O操作的服务时间。如果svctm值和await值很接近，则表示I/O几乎没有等待，如果await的值远高于svctm的值，则表示I/O队列等待太长

%util：在统计的时间内总共有多少的时间用于处理I/O操作,即被消耗的CPU的百分比。例如统计时间间隔是1s，那么这个设备有0.65s在处理I/O，有0.35s处于空闲。那么这个设备的%util=0.65/1=65%，一般地，如果该参数是100%表示设备已经接近满负荷运行了（当然如果是多磁盘，即使%util是100%，因为磁盘的并发能力，所以磁盘使用未必就到了瓶颈）



# 3 磁盘阵列吞吐量与IOPS两大瓶颈分析**

## 3.1 吞吐量

吞吐量主要取决于阵列的构架，光纤通道的大小(现在阵列一般都是光纤阵列，至于SCSI这样的SSA阵列，我们不讨论)以及硬盘的个数。阵列的构架与每个阵列不同而不同，他们也都存在内部带宽(类似于pc的系统总线)，不过一般情况下，内部带宽都设计的很充足，不是瓶颈的所在。

光纤通道的影响还是比较大的，如数据仓库环境中，对数据的流量要求很大，而一块2Gb的光纤卡，所77能支撑的最大流量应当是2Gb/8(小B)=250MB/s(大B)的实际流量，当4块光纤卡才能达到1GB/s的实际流量，所以数据仓库环境可以考虑换4Gb的光纤卡。

最后说一下硬盘的限制，这里是最重要的，当前面的瓶颈不再存在的时候，就要看硬盘的个数了，我下面列一下不同的硬盘所能支撑的流量大小：

	10K rpm：10M/s
    15K rpm：13M/s
    ATA: 8M/s

那么，假定一个阵列有120块15K rpm的光纤硬盘，那么硬盘上最大的可以支撑的流量为120*13=1560MB/s，如果是2Gb的光纤卡，可能需要6块才能够，而4Gb的光纤卡，3-4块就够了。

## 3.2 IOPS

决定IOPS的主要取决与阵列的算法，cache命中率，以及磁盘个数。阵列的算法因为不同的阵列不同而不同.在使用这个存储之前，有必要了解这个存储的一些算法规则与限制。

cache的命中率取决于数据的分布，cache size的大小，数据访问的规则，以及cache的算法，如果完整的讨论下来，这里将变得很复杂，可以有一天好讨论了。我这里只强调一个cache的命中率，如果一个阵列，读cache的命中率越高越好，一般表示它可以支持更多的IOPS，为什么这么说呢?这个就与我们下面要讨论的硬盘IOPS有关系了。

硬盘的限制，每个物理硬盘能处理的IOPS是有限制的，如
	
	10K rpm：100 IOPS
    15K rpm：150 IOPS
    ATA: 50 IOPS

如果一个阵列有120块15K rpm的光纤硬盘，那么，它能撑的最大IOPS为120*150=18000，这个为硬件限制的理论值，如果超过这个值，硬盘的响应可能会变的非常缓慢而不能正常提供业务。

在raid5与raid10上，读iops没有差别，但是，相同的业务写iops，最终落在磁盘上的iops是有差别的，而我们评估的却正是磁盘的IOPS，如果达到了磁盘的限制，性能肯定是上不去了。

那我们假定一个case，业务的iops是10000，读cache命中率是30%，读iops为60%，写iops为40%，磁盘个数为120，那么分别计算在raid5与raid10的情况下，每个磁盘的iops为多少。

　　raid5:
    单块盘的iops = (10000*(1-0.3)*0.6 + 4 * (10000*0.4))/120 = (4200 + 16000)/120= 168

　　这里的10000*(1-0.3)*0.6表示是读的iops，比例是0.6，除掉cache命中，实际只有4200个iops
　　而4 * (10000*0.4) 表示写的iops，因为每一个写，在raid5中，实际发生了4个io，所以写的iops为16000个

　　为了考虑raid5在写操作的时候，那2个读操作也可能发生命中，所以更精确的计算为：

　　单块盘的iops = (10000*(1-0.3)*0.6 + 2 * (10000*0.4)*(1-0.3) + 2 * (10000*0.4))/120

　　= (4200 + 5600 + 8000)/120

　　= 148

　　计算出来单个盘的iops为148个，基本达到磁盘极限

　　raid10

　　单块盘的iops = (10000*(1-0.3)*0.6 + 2 * (10000*0.4))/120

　　= (4200 + 8000)/120

　　= 102

　　可以看到，因为raid10对于一个写操作，只发生2次io，所以，同样的压力，同样的磁盘，每个盘的iops只有102个，还远远低于磁盘的极限iops。

　　在一个实际的case中，一个恢复压力很大的standby(这里主要是写，而且是小io的写)，采用了raid5的方案，发现性能很差，通过分析，每个磁盘的iops在高峰时期，快达到200了，导致响应速度巨慢无比。后来改造成raid10，就避免了这个性能问题，每个磁盘的iops降到100左右。

# 4.参考资料 #
**hdparm:**  
http://elf8848.iteye.com/blog/1731274  
http://elf8848.iteye.com/blog/1731301

**fio**  
http://blog.yufeng.info/archives/2104  
https://wsgzao.github.io/post/fio/
https://www.linux.com/learn/inspecting-disk-io-performance-fio