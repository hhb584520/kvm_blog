# Qemu 监控器 #

Qemu 监控器是 QEMU与实现用户交互的一种控制台，一般用于为QEMU模拟器提供较为复杂的功能，包括如下：

-  为客户机添加和移除一些媒体镜像（如CD-ROM）
-  暂停和继续客户机的运行，快照的建立和删除
-  从磁盘文件中保持和恢复客户机状态
-  客户机动态迁移，查询客户机当前各种状态参数....


## 1. Qemu monitor 的切换和配置 ##

     要使用 Qemu monitor，首先要切换到 monitor窗口，然后才能使用命令操作
     Ctrl + Alt +2 切换过去
     Ctrl + Alt +1 切换回来
     如果使用 SDL 显示，且在使用 qemu-kvm 命令行启动客户机时添加了 “-alt-grab" 或 ”-ctrl-grab" 参数，则会使该组合键被对应修改为
     "Ctrl + Alt + Shift + 2" 或 "右Ctrl + 2"
     如果所有的情况都有一定要到图形窗口才能操作 Qemu monitor，那么在某些完全不能使用图形界面的情况下将会受到一些限制，其实
		Qemu 提供了如下的参数来灵活地控制 monitor 的重定向
     -monitor dev  将 monitor 重定向到宿主机的 dev 设备上。这个设备写法有很多种
    1)  vc 
        不加 -monitor 默认使用该选项，即虚拟控制台，只有该模式下才能使用 “Ctrl+Alt+2” 切换，另外还可以指定宽度和长度，如 "vc:800*600"
    表示宽度和长度分别是800像素和600像素。
     2) /dev/XXX
        使用宿主机的终端(tty), 如 “-monitor /dev/ttyS0" 是将 monitor 重定向到宿主机的 ttyS0 串口上去，而且 QEMU 会根据QEMU模拟器的配置
    来自动设置该串口的一些参数。
     3) null 
         空设备，表示不将 monitor 重定向到任何设备上，无论怎样也不能连接上 monitor.
      4) pty
           重定向到虚拟终端，系统默认自动创建一个新的虚拟终端。
      5) none
           不重定向到任何设备中
      6) file:filename
            重定向到 filename 这个文件中，只能保存串口输出，不能输入字符进行交互。
      7) stdio
            重定向到当前的标准输入输出。
      8) pipe:filename
            重定向到 filename 名字的管道
      9) 其他
            还可以将串口重定向到 TCP 或 UDP 建立的网络控制台中，还可以重定向到 Unix Domain Socket.


## 2. 常用命令介绍 ##
### 2.1 help 显示帮助信息 ###

    help 或 ？ [ cmd ]
    (qemu) help migrate
    (qemu) help device_add
    (qemu) ? savevm

### 2.2 info 显示系统状态 ###

    (qemu) info version    // 查看 QEMU 的版本信息
    (qemu) info kvm         // 查看 当前 QEMU 是否有 KVM的支持
    (qemu) info name      // 显示当前客户机的名字
    (qemu) info stattus    // 显示当前客户机的运行状态，可能为运行中或暂停状态。
    (qemu) info cpus       // 查看客户机各个 vCPU 的状态。
    (qemu) info history    // 查看当前的 monitor 中命令行执行的历史记录。

    info 的相关命令可以通过 (qemu) help info 来查

### 2.3 已经使用过的命令 ###

    1) (qemu) commit
    提交修改部分的变化到磁盘镜像中（在使用了“-snapshot”启动参数），或提交变化部分到使用后端镜像文件。

    2) (qemu) cont 或 c
    恢复 QEMU 模拟器继续工作。另外，“stop” 是暂停 QEMU 模拟器的命令。

    3) (qemu) change
    改变一个设备的配置，如“change vnc localhost:2”改变VNC的配置
    更改 VNC 连接的密码 "chage vnc passwd"
    改变客户机中光驱加载的光盘 "change ide1-cd0 /path/to/some.iso"

    4) (qemu) balloon 512
     表示改变分配给客户机的内存大小为 512 MB

    5) (qemu) savevm/loadvm/delvm
        savevm mytag: 表示根据当前客户机状态创建标志位 mytag 的快照。
        loadvn  mytag: 表示加载客户机标志位 mytag 快照时的状态。
        delvm mytag  : 表示删除 mytag 标志的客户机快照。 

## 4. 其它常见命令 ##

## 4.1 cpu index ##

        设置默认的 CPU 为 index 数字指定的，在 info cpus 命令的输出中，星号标识的CPU就是系统默认的CPU，
    几乎所有的中断请求都会优先发到默认CPU上去。如下命令行演示了 “cpu index”。
         (qemu) info cpus
         (qemu) cpu 1
         (qemu) info cpus

## 4.2 log 和 logfile ##

      log item1[,...] 将指定的 item1 项目的 log 保存到 /tmp/qemu.log 中；
      logfile filename 命令设置 log 文件输出到 filename 文件中而不是默认的 /tmp/qemu.log 文件中。 
    
## 4.3 sendkey keys ##

      向客户机发送 keys 按键（或组合键），就如同非虚拟化环境中那样的按键效果。如果同时发送的是多个按键的组合，则按键中间用 '-' 来连接。
      (qemu) sendkey ctrl-alt-f2   // f2 就是将客户机的显示输出到 tty2 终端， f1 是tty1 。ssh 登录到虚拟机后可以查看当前系统中查看当前系统已登录用户的状态：who
      (qemu) sendkey ctrl-alt-delete // 在文本模式的客户机 Linux系统中组合键会重启系统
      (qemu) sendkey ctrl-alt-f2

## 4.4 system 命令 ##

      system_powerdown: 向客户机发送关闭电源的事件通知，一般会让客户机执行关机操作。
      system_reset: 让客户机系统重置，相当于直接拔掉电源，然后插上电源，按开机键开机。
      system_wakeup: 将客户机从 暂停 中唤醒。

## 4.5 x 和 xp ##

      x /fmt addr 转存出从addr 开始的虚拟内存地址
      xp /fmt addr 转存出从addr 开始的物理内存地址

      fmt 格式的语法：/{count}{format}{size}
      - count: 表示被转存出来的条目数。
      - format: x(hex，16进制)、d(有符号的十进制)、u(无符号的十进制)、o(八进制)、c(字符)、i(asm 汇编指令)。
      - size: b/h/w/g(分别是 8/16/32/64位)
   
      例子:
         x/10i $eip
         xp/80xh 0xb8000

## 4.6 p 和 print fmt expr ##

       (qemu) p 100+200
       (qemu) print 100+200
       (qemu) p $ecx

## 4.7 q 或 quit  ##

       执行 q 或 quit 命令，直接退出 QEMU 模拟器，QEMU进程会被杀掉。



## Ref
https://en.wikibooks.org/wiki/QEMU/Monitor










