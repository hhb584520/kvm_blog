# 1. SMEP #

SMEP(Supervisor Mode Execution Protection)
    
参看 SMEP.pdf
渗透（exploitation）攻击，会诱导系统在最高执行级别（Ring0）上访问在用户空间（ring3)的数据和执行用户空间在 SMEP 特性的支持下，在运行管理模式的 CPU 不能执行用户模式的内存页，可以较好地阻止前面提到的那种渗透攻击。    当控制寄存器 CR4 寄存器的 20 位（第21位）被设置为1时，表示 SMEP特性是打开状态。

    qemu-system-x86_64 rhel6u3.img -m 1024 -net nic -net tap -cpu host
    cat /proc/cpuinfo | grep smep
   
      

# 2. Cgroups #
    
在KVM 虚拟化环境中，每个客户机操作系统使用系统的一部分物理资源。当一个客户机对资源的消耗过大时，它可能会占用该系统的大部分资源此时，其他的客户机对相同资源的请求就会受到严重影响，可能导致其他客户机响应速度过慢甚至失去响应。为了让所有客户机都能够按照预先的比例来占用物理资源，我们需要对客户机能使用的物理资源做控制，-m, -smp 都是比较粗粒度的控制，不能控制仅适用1个CPU的 50%的资源。由于每个客户机就是宿主机 Linux 系统上的一个普通 qemu-kvm 进程，所以可以通过控制 qemu-kvm 进程使用的资源来达到控制客户机的目的。

Cgroups(Control groups) 是Linux内核中的一个特性，用于限制、记录和隔离进程组对系统物理资源的使用。它主要提供以下功能：

     1)  资源限制，让进程组被设置为使用不能超过某个界限的资源数量。如内存子系统可以为进程组设定一个内存使用的上限。
     2)  优先级控制，让不同的进程组有不同的优先级。可以让一些进程组占用较大的CPU或磁盘I/O吞吐量的百分比，另一些进程组占用较
          小的百分比
     3)  记录（Accounting)，衡量每个进程组实际占用的资源数量，可以用于客户机收费。
     4)  隔离，对不同的进程组使用不同的命名空间，不同的进程组之间不能看到相互的进程、网络连接、文件访问等信息，如使用 ns 子系
          统就可以使不同的进程组使用不同的命名空间
     5)  控制，控制进程组的暂停、添加检查点、重启等，如使用 freezer 子系统可以将进程组挂起和恢复。 

在Cgroup中有这样四个概念，可以说理解了这四个概念：

     1) Subsystems: 称之为子系统，一个子系统就是一个资源控制器，比如 cpu子系统就是控制cpu时间分配的一个控制器。
     2) Hierarchies: 可以称之为层次体系也可以称之为继承体系，指的是Control Groups是按照层次体系的关系进行组织的。
     3) Control Groups: 一组按照某种标准划分的进程。进程可以从一个Control Groups迁移到另外一个Control Groups中，同时Control Groups
         中的进程也会受到这个组的资源限制。
     4) Tasks: 在cgroups中，Tasks就是系统的一个进程。

     查看当前系统支持的子系统：	# lssubsys -am

     
**操作示例**

1) 启动两个客户机和其中的 mysql 服务器。假设需要优先级高的客户机在 qemu-kvm 命令行启动时加上 "-name high_prio" 的参数来指定其名称，而优先级低的客
户机有 "-name low_prio" 参数。在它们启动时为它们取不同的名称，仅仅是为了后面操作中方便区别出两个客户机。
     

2) 添加 blkio 子系统到 /cgroup/blkio 这个控制群组上，并创建高优先级和低优先级两个群组。

       #  mkdir -p /cgroup/blkio     # 创建了名为 blkio 的层级
       #  mount -t cgroup -o blkio blkio /cgroup/blkio 
       #  mkdir /cgroup/blkio/high_prio
       #  mkdir /cgroup/blkio/low_prio
       #  ls /cgroup/blkio/high_prio/

3) 分别将高优先级和低优先级的客户机的 qemu-kvm 进程移动到相应的控制群组下面去。

       #!/bin/bash
       pid_list=$(ps -elf | grep qemu | grep "high_prio" | awk '{print $4}')
       for pid in $pid_list
       do
                echo $pid >> /cgroup/blkio/high_prio/tasks
       done

4) 分别设置高低优先级的控制群组中块设备 I/O 访问的权重，这里假设高低优先级的比例为 10：1，命令如下：

        # echo 1000 > /cgroup/blkio/high_prio/blkio.weight
        # echo 100 > /cgroup/blkio/low_prio/blkio.weight

5) 块设备 I/O 访问控制的效果分析。假设宿主机系统中磁盘 I/O 访问的最大值是每秒写入 66MB，高的 60MB，低 6MB.
       
https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Resource_Management_Guide/ch01.html#sec-How_Control_Groups_Are_Organized

Image result


# 3. SELinux 和 sVirt #
     
几乎可以肯定每个人都听说过 SELinux (更准确的说，尝试关闭过)，甚至某些过往的经验让您对 SELinux 产生了偏见。不过随着日益增长的 0-day 安全漏洞，或许现在是时候去了解下这个在 Linux 内核中已经有8年历史的强制性访问控制系统(MAC)了。

SELinux 与强制访问控制系统，SELinux 全称 Security Enhanced Linux (安全强化 Linux)，是 MAC (Mandatory Access Control，强制访问控制系统)的一个实现，目的在于明确的指明某个进程可以访问哪些资源(文件、网络端口等)。

强制访问控制系统的用途在于增强系统抵御 0-Day 攻击(利用尚未公开的漏洞实现的攻击行为)的能力。所以它不是网络防火墙或 ACL 的替代品，在用途上也不重复。举例来说，系统上的 Apache 被发现存在一个漏洞，使得某远程用户可以访问系统上的敏感文件(比如 /etc/passwd 来获得系统已存在用户)，而修复该安全漏洞的 Apache 更新补丁尚未释出。此时 SELinux 可以起到弥补该漏洞的缓和方案。因为 /etc/passwd 不具有 Apache 的访问标签，所以 Apache 对于 /etc/passwd 的访问会被 SELinux 阻止。相比其他强制性访问控制系统，SELinux 有如下优势：

- 控制策略是可查询而非程序不可见的。
- 可以热更改策略而无需重启或者停止服务。
- 可以从进程初始化、继承和程序执行三个方面通过策略进行控制。
- 控制范围覆盖文件系统、目录、文件、文件启动描述符、端口、消息接口和网络接口。

那么 SELinux 对于系统性能有什么样的影响呢?根据 Phoronix 在 2009 年使用 Fedora 11 所做的横向比较来看，开启 SELinux 仅在少数情况下导致系统性能约 5% 的降低。SELinux 是不是会十分影响一般桌面应用及程序开发呢?原先是，因为 SELinux 的策略主要针对服务器环境。但随着 SELinux 8年来的广泛应用，目前SELinux 策略在一般桌面及程序开发环境下依然可以同时满足安全性及便利性的要求。以刚刚发布的 Fedora 15 为例，笔者在搭建完整的娱乐(包含多款第三方原生 Linux 游戏及 Wine 游戏)及开发环境(Android SDK + Eclipse)过程中，只有 Wine 程序的首次运行时受到 SELinux 默认策略的阻拦，在图形化的“SELinux 故障排除程序”帮助下，点击一下按钮就解决了。

了解和配置 SELinux

1). 获取当前 SELinux 运行状态
        # getenforce
       
可能返回结果有三种：Enforcing、Permissive 和 Disabled。Disabled 代表 SELinux 被禁用，Permissive 代表仅记录安全警告但不阻止可疑行为，Enforcing 代表记录警告且阻止可疑行为。目前常见发行版中，RHEL 和 Fedora 默认设置为 Enforcing，其余的如 openSUSE 等为 Permissive。
     
2). 改变 SELinux 运行状态
         
setenforce [ Enforcing | Permissive | 1 | 0 ]
         
该命令可以立刻改变 SELinux 运行状态，在 Enforcing 和 Permissive 之间切换，结果保持至关机。一个典型的用途是看看到底是不是 SELinux 导致某个服务或者程序无法运行。若是在 setenforce 0 之后服务或者程序依然无法运行，那么就可以肯定不是 SELinux 导致的。
          
若是想要永久变更系统 SELinux 运行环境，可以通过更改配置文件 /etc/sysconfig/selinux 实现。注意当从 Disabled 切换到 Permissive 或者 Enforcing 模式后需要重启计算机并为整个文件系统重新创建安全标签(touch /.autorelabel && reboot)。

3). SELinux 运行策略
         
配置文件 /etc/sysconfig/selinux 还包含了 SELinux 运行策略的信息，通过改变变量 SELINUXTYPE 的值实现，该值有两种可能：targeted 代表仅针对预制的几种网络服务和访问请求使用 SELinux 保护，strict 代表所有网络服务和访问请求都要经过 SELinux。
         
RHEL 和 Fedora 默认设置为 targeted，包含了对几乎所有常见网络服务的 SELinux 策略配置，已经默认安装并且可以无需修改直接使用。
         
若是想自己编辑 SELinux 策略，也提供了命令行下的策略编辑器 seedit 以及 Eclipse 下的编辑插件 eclipse-slide 。

# 4. Tboot 和 TXT #
    
省略

# 5. 其它安全策略 #
## 5.1 镜像文件加密 ##

不加密转加密
      qemu-img create -f qcow2 -o size=8G guest.qcow2
      qemu-img convert -o encryption -O qcow2  guest.qcow2 encrypted.qcow2 输入密码

加密的创建密码
      qemu-img create -f qcow2 -o backing_file=rhel6u3.img,encryption encrypted.qcow2
      qemu-img convert -o encryption -O qcow2 encrypted.qcow2  encrypted1.qcow2 输入密码