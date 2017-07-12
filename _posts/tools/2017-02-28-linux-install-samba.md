# Samba 安装及配置 #

Samba 是 SMB/CIFS 网络协议的重新实现, 它作为 NFS 的补充使得在 Linux 和 Windows 系统中进行文件共享、打印机共享更容易实现。了解到一些用户需要简化访问学习成本，满足基础的权限控制管理，并支持实时编辑和保存文件,查询了相关资料显示 samba 是最佳选择。

## 1.直接 yum 安装 samba 服务 ##

	yum install samba samba-client samba-common

## 2.验证一些安装了那些 samba 相关的软件包 ##

    [root@c7 ~]# rpm -qa | grep samba
    samba-4.1.12-23.el7_1.x86_64
    samba-libs-4.1.12-23.el7_1.x86_64
    samba-common-4.1.12-23.el7_1.x86_64
    samba-client-4.1.12-23.el7_1.x86_64

## 3.实践 samba 配置，需要完成：##

- 实现匿名访问，验证可以读写文件、目录
- 实现指定用户的访问
- 实现对特定的访问地址进行限制
- 实现访问windows系统中的共享资源

## 4.备份 samba 配置。 ##

	#过滤杂七杂八的注释备份一份
	egrep -v "^.*#" /etc/samba/smb.conf > /etc/samba/smb_$(date +%d-%m-%y).conf

## 5.一些基本的配置 ##

常用的 samba 共享目录参数

    [MyShare]
    	comment = grind’s file  #对共享备注
    	path = /home/grind  #共享文件系统路径
    	allow hosts = host(subnet)  #允许访问的主机
    	deny hosts = host(subnet)   #禁止访问的主机
    	writable = yes|no   #是否可写
    	readonly = yes|no   #是否只读  
    	user = user(@group) #可使用该资源的用户
    	valid users = user(@group)  #白名单用户或组
    	invalid users = user(@group)#黑名单用户或组
    	read list = user(@group)#只读用户或组列表
    	write list = user(@group)   #可写用户或组列表
    	admin list = user(@group)   #指定能管理该共享资源（包括读写和权限赋予等）的用户和组
    	public = yes|no #是否能给游客帐号访问
    	guest ok = yes|no   #是否能给游客账号访问
    	hide dot files = yes|no #是否像unix那样隐藏以“.”号开头的文件
    	create mode = 0755  #指明新建立的文件的属性，一般是0755
    	directory mode = 0755   #指明新建立的目录的属性，一般是0755
    	sync always = yes|no#指明对该共享资源进行写操作后是否进行同步操作
    	short preserve case = yes|no#指明是否区分文件名大小写。
    	preserve case = yes|no  #指明保持大小写。
    	case sensitive = yes|no #指明是否对大小写敏感，一般选no,不然可能引起错误。
    	mangle case = yes|no#指明混合大小写
    	default case = upper|lower  #指明缺省的文件名是全部大写还是小写
    	force user = grind  #强制把建立文件的属主是谁
    	wide links = yes|no #指明是否允许共享外符号连接
    	max connections = 100   #设定同时连接数
    	delete readonly = yes|no#指明能否删除共享资源里面已经被定义为只读的文件

## 6.准备一些目录和用户 ##

    mkdir /home/development
    mkdir /home/share
    chmod -R 755 /home/development/
    chmod -R 755 /home/share/
    useradd anycto -s /sbin/nologin
    smbpasswd -a anycto
    pdbedit -L


## 7.允许匿名用户访问，删除，创建，删除操作的配置和指定用户和网段的访问的目录配置 ##

    [global]
    	workgroup = MYGROUP
    	server string = Samba Server Version %v
    	log file = /var/log/samba/log.%m
    	max log size = 50
    	cups options = raw
    	#匿名用户使用这个参数
    	#map to guest =Bad User
    	#指定用户访问需要修改成
    	security = user
    	passdb backend = tdbsam
    	#匿名用户可读写
    [share]
    	path = /home/share
    	public = yes
    	browseable= yes
    	writable= yes
    	create mask = 0644
    	directory mask = 0755
    	#指定用户访问
    [development]
    	comment = All Development File
    	path = /home/development
    	browseable= yes
    	create mask = 0644get
    	directory mask = 0755
    	#valid users = anycto,cnhzz
    	#write list = anycto
    	user = anycto
    	read only = No
    	guest ok = No

使用testparm测试配置是否有问题，使用testparm –v命令可以详细的列出smb.conf支持的配置参数。

## 8.启动 smb 和 nmb ##

组成Samba运行的有两个服务，一个是SMB，另一个是NMB；SMB是Samba 的核心启动服务，主要负责建立 Linux Samba服务器与Samba客户机之间的对话， 验证用户身份并提供对文件和打印系统的访问，只有SMB服务启动，才能实现文件的共享，监听139 TCP端口；而NMB服务是负责解析用的，类似与DNS实现的功能，NMB可以把Linux系统共享的工作组名称与其IP对应起来，如果NMB服务没有启 动，就只能通过IP来访问共享文件。

    systemctl start smb.service nmb.service
    systemctl status smb.service nmb.service
    systemctl enable smb.service nmb.service 

查看启动的端口

    State  Recv-Q Send-QLocal Address:Port  Peer Address:Port
    LISTEN 0  50*:139  *:*
    LISTEN 0  128   *:22   *:*
    LISTEN 0  100   127.0.0.1:25   *:*
    LISTEN 0  50*:445  *:*
    LISTEN 0  50   :::139 :::*
    LISTEN 0  128  :::22  :::*
    LISTEN 0  100 ::1:25  :::*
    LISTEN 0  50   :::445 :::*

查看启动 samba 进程

    [root@c7 ~]# ps aux | grep smb
    root  1969  0.0  0.5 371836  5376 ?Ss   15:30   0:00 /usr/sbin/smbd
    root  1970  0.0  0.2 371836  2976 ?S15:30   0:00 /usr/sbin/smbd
    nobody1972  0.0  0.5 380100  5968 ?S15:30   0:00 /usr/sbin/smbd
    root  1980  0.0  0.0 112656   968 pts/0S+   15:31   0:00 grep --color=auto smb
    [root@c7 ~]# ps aux | grep nmb
    root  1968  0.0  0.2 300960  2516 ?Ss   15:30   0:00 /usr/sbin/nmbd
    root  1982  0.0  0.0 112656   972 pts/0S+   15:31   0:00 grep --color=auto nmb

可使用smbstatus查看当前 samba 服务的状态

    [root@c7 ~]# smbstatus
     
    Samba version 4.1.12
    PID Username  Group Machine
    -------------------------------------------------------------------
    12090 anyctoanycto10.211.55.2  (ipv4:10.211.55.2:57970)
     
    Service  pid machine   Connected at
    -------------------------------------------------------
    development   12090   10.211.55.2   Thu Aug  6 18:58:31 2015
     
    Locked files:
    Pid  UidDenyMode   Access  R/WOplock   SharePath   Name   Time
    --------------------------------------------------------------------------------------------------
    120901000   DENY_NONE  0x100081RDONLY NONE /home/development   .   Thu Aug  6 19:01:56 2015

9、在打开 selinux 的情况下，需要修改 selinux 一些参数才能会有读写的权限。

默认情况下是这样：

    [root@c7 ~]# getsebool -a | grep samba
    samba_create_home_dirs --> off
    samba_domain_controller --> off
    samba_enable_home_dirs --> off
    samba_export_all_ro --> off
    samba_export_all_rw --> off
    samba_load_libgfapi --> off
    samba_portmapper --> off
    samba_run_unconfined --> off
    samba_share_fusefs --> off
    samba_share_nfs --> off
    sanlock_use_samba --> off
    use_samba_home_dirs --> off
    virt_sandbox_use_samba --> off
    virt_use_samba --> off

需要调整参数确保是这样：

    samba_create_home_dirs --> on
    samba_domain_controller --> on
    samba_enable_home_dirs --> on
    samba_export_all_ro --> on
    samba_export_all_rw --> on

因此需要执行：

    setsebool -P samba_create_home_dirs=1
    setsebool -P samba_domain_controller=1
    setsebool -P samba_enable_home_dirs=1
    setsebool -P samba_export_all_ro=1
    setsebool -P samba_export_all_rw=1

## 10.在 windows10上测试 samba 服务。 ##

在修改上述的 selinux 后需要重启一下 samba 在进行测试。

1.Windows上访问samba

在“计算机”中输入：\\xxx.xxx.xxx.xxx\

2.Windows断开samba共享连接，实在不行可以选择注销或者重启

在【开始】→【运行】→【CMD】回车中输入：net use * /del /y

3.将samba共享的Linux目录映射成Windows的一个驱动器盘符

在【右键计算机】→【映射网络驱动器】→【文件夹\XX.XX.XX.XX\】
