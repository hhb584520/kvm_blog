# Ubunt 使用 #

- 开启root用户远端登录
- 修改环境变量
- 配置开机启动服务
- PXE
- 中文字符设置
- VNC配置


## 1.root用户 ##
### 1.1 root修改密码 ###
ubuntu的root默认是禁止使用的，在安装的时候也没要求你设置root的密码，和红帽系统系列这里是不同的。要使用，给root设置密码就行了。

    sudo passwd root

如果只是普通用户密码忘了，用root就可以修改。

如果root都忘记了，就进入单用户模式，这里跟红帽系统系列也不同。进入单用户模式:

- 开机到grub时，用上下键移到第二行的恢复模式，按e（注意不是回车） .
- 把ro single 改成rw single init=/bin/bash 然后按ctrl+x 就可以进入 单用户模式，进去干什么都行了。可以改普通用户密码，也可以改root密码。按ctrl+alt+delete 重启（我试过用命令关机，重启都不行，只能用这个）。

### 1.2 开发root ssh 登录权限 ###

刚安装了Ubuntu 14.04 server的虚拟机，普通帐号可以远程登录，但是root不行，输入密码后一直报错：

permission denied

最后发现ssh的配置(/etc/ssh/sshd_config)不大一样，14.04的默认配置是：

    [plain] view plain copy 在CODE上查看代码片派生到我的代码片
    PermitRootLogin without-password  
    
    要改成
    [plain] view plain copy 在CODE上查看代码片派生到我的代码片
    PermitRootLogin yes  
    
    重启服务即可：
    [plain] view plain copy 在CODE上查看代码片派生到我的代码片
    restart ssh  

## 2.修改环境变量 ##
Ubuntu Linux系统环境变量配置文件： 

- /etc/profile : 在登录时,操作系统定制用户环境时使用的第一个文件 ,此文件为系统的每个用户设置环境信息,当用户第一次登录时,该文件被执行。 
- /etc /environment : 在登录时操作系统使用的第二个文件, 系统在读取你自己的profile前,设置环境文件的环境变量。 
- ~/.profile :  在登录时用到的第三个文件 是.profile文件,每个用户都可使用该文件输入专用于自己使用的shell信息,当用户登录时,该文件仅仅执行一次!默认情况下,他设置一些环境变量,执行用户的.bashrc文件。 
- /etc/bashrc : 为每一个运行bash shell的用户执行此文件.当bash shell被打开时,该文件被读取. 
- ~/.bashrc : 该文件包含专用于你的bash shell的bash信息,当登录时以及每次打开新的shell时,该该文件被读取。 


PASH环境变量的设置方法： 

方法一：用户主目录下的.profile或.bashrc文件（推荐） 

    登录到你的用户（非root），在终端输入： 
    $ sudo gedit ~/.profile(or .bashrc) 
    可以在此文件末尾加入PATH的设置如下： 
    export PATH=”$PATH:your path1:your path2 ...” 
    保存文件，注销再登录，变量生效。 
    该方式添加的变量只对当前用户有效。 

方法二：系统目录下的profile文件（谨慎） 

    在系统的etc目录下，有一个profile文件，编辑该文件： 
    $ sudo gedit /etc/profile 
    在最后加入PATH的设置如下： 
    export PATH=”$PATH:your path1:your path2 ...” 
    该文件编辑保存后，重启系统，变量生效。 
    该方式添加的变量对所有的用户都有效。 

方法三：系统目录下的 environment 文件（谨慎） 

    在系统的etc目录下，有一个environment文件，编辑该文件： 
    $ sudo gedit /etc/environment 
    找到以下的 PATH 变量： 
    PATH="<......>" 
    修改该 PATH 变量，在其中加入自己的path即可，例如： 
    PATH="<......>:your path1:your path2 …" 
    各个path之间用冒号分割。该文件也是重启生效，影响所有用户。 
    注意这里不是添加export PATH=… 。 

方法四：直接在终端下输入 

    $ sudo export PATH="$PATH:your path1:your path2 …" 
    这种方式变量立即生效，但用户注销或系统重启后设置变成无效，适合临时变量的设置。 


注 意：方法二和三的修改需要谨慎，尤其是通过root用户修改，如果修改错误，将可能导致一些严重的系统错误。因此笔者推荐使用第一种方法。另外嵌入式 Linux的开发最好不要在root下进行（除非你对Linux已经非常熟悉了！！），以免因为操作不当导致系统严重错误。 

下面是一个对environment文件错误修改导致的问题以及解决方法示例： 

问题：因为不小心在 etc/environment里设在环境变量导致无法登录 
提示：不要在 etc/environment里设置 export PATH这样会导致重启后登录不了系统 
解决方法： 
在登录界面 alt +ctrl+f1进入命令模式，如果不是root用户需要键入（root用户就不许这么罗嗦，gedit编辑会不可显示） 
/usr/bin/sudo /usr/bin/vi /etc/environment 
光标移到export PATH** 行，连续按 d两次删除该行； 
输入:wq保存退出； 
然后键入/sbin/reboot重启系统（可能会提示need to boot，此时直接power off） 

## 3. 配置开机启动服务 ##
### 3.1背景知识 ###
Linux系统任何时候都运行在一个指定的运行级上，并且不同的运行级程序和服务都不同，所要完成的工作和要达到的目的也不同，系统可以在这些运行级之间进行切换，来完成不同的工作。

运行级别等级：  
0        系统停机状态  
1        单用户模式，只准许root用户对系统进系维护  
2～5  多用户模式（其中3为字符界面、5为图形界面）  
6         重启启动  
在这里需要注意的是，在Debian下（ubuntu其中之一）level2～5是没有任何区别的。

使用以下命令，可以查看当前的运行级别：

	$ runlevel

runlevel显示上次的运行级别和当前的运行级别，“N”表示没有上次的运行级别。

使用以下命令，可以切换运行级别：

	$ init [0123456]

init 0 表示关机

### 3.2启动步骤 ###
- 读取MBR信息，启动Boot Manager，Linux通常使用GRUB作为Boot Manager。
- 加载系统内核，启动init进程。init进程是Linux的根进程，所有的系统进程都是它的子进程。
- init进程读取/etc/inittab文件中的信息，并进入预设的运行级别。在这里需要说下的是，在ubuntu的6.10版本以后，就没有了/etc/inittab文件，是因为inittab已经被update软件包所取代了，具体的可以查看/usr/share/doc/update目录。就不在这里介绍了。
- 执行/etc/rcS.d/目录下的脚本，然后是/etc/rcX.d/目录下的脚本，X代表的是数字0～6。rcS.d和rcX.d目录下的文件都是以，S或K加上两位数字组成的，其中S代表start，K代表kill，而两位数字代表启动顺序，数字越大代表级别越低。

### 3.3设置开机启动项 ###

	$ apt-get install sysv-rc-conf
	$ sysv-rc-conf

它具有操作简单，简洁的操作界面，你可以使用鼠标点击，也可以使用键盘操作，空格键代表选择，“X”表示开启服务，Ctrl+N下一页，Ctrl+P上一页，Q退出。

## 4. PXE ##
### 4.1 PXE简介###
PXE (Pre-boot Execution Environment)：是由Intel设计的协议，它可以使计算机通过网络启动。
TFTP (trivial file transfer protocol)：一种开销很小的文件传输协议。因简单、高效，常用于网络设备的OS和配置更新.
DHCP (Dynamic Host Control Protocol) ：动态主机控制协议。用于集中、动态的给客户机分配IP地址.
PXE协议分为Client和Server两端，PXE Client在网卡的ROM中，当计算机引导时，BIOS把PXE Client调入内存执行，并显示出命令菜单，经用户选择后，PXE Client将放置在远端的操作系统通过网络下载到本地运行。
PXE协议的成功运行需要解决以下两个问题：
既然是通过网络传输，那么计算机在启动时，它的IP地址由谁来配置
通过什么协议下载Linux内核和根文件系统
第一个问题：使用DHCP服务器动态分配IP地址给PXE Client。
第二个问题：主机的ROM中内置了TFTP客户端程序，使用TFTP协议从服务器下载所需文件。

### 4.2 安装环境 ###
提供PXE的服务器的IP为192.168.1.133
操作系统为ubuntu12.04.3 server
ubuntu镜像下载位置：/home/shang/ubuntu-12.04.3-server-amd64.iso
对服务器更新软件源，防止出现软件无法下载的情况

	# sudo apt-get update

安装配置Nginx

	# sudo apt-get install nginx

修改/etc/nginx/sites-available/default

	location / {
	    # First attempt to serve request as file, then
	    # as directory, then fall back to index.html
	    # comment this --> try_files $uri $uri/ /index.html;
	    # Uncomment to enable naxsi on this location
	    # include /etc/nginx/naxsi.rules
	}

如上注释掉 ： try_files $uri $uri/ /index.html;
try_files含义参见：nginx-coremodule，其实就是文件路径选择顺序，$uri是客户端请求的链接。未注释前，顺序是：先精确查找$uri，如果没有此文档，则重定位到uri/目录下，还没找到时最后重定位到/index.html.
注释掉之后：如果没有找到文档，则直接返回404。至于为什么要注释掉还没有搞清楚，谁知道希望能告知哈！但是不注释掉，后面安装会出错。

	# sudo service nginx start

使用浏览器访问此IP 192.168.1.133，如果出现 welcome to nginx，则配置成功

### 4.3 TFTP服务安装配置 ###
安装tftpd（tftp服务器）、tftp（tftp客户端）以及xinetd（超级服务器）
tftp通过xinetd守护进程来管理，详细信息参见：Linux 超级守护进程 xinetd

	# sudo apt-get install tftpd tftp xinetd

增加 /etc/xinetd.d/tftp，添加如下内容:

	service tftp
	{
	  protocol = udp
	  port = 69
	  socket_type = dgram
	  wait = yes
	  user = nobody
	  server = /usr/sbin/in.tftpd
	  server_args = /var/lib/tftpboot
	  disable = no 
	}

创建tftp服务器的根目录

	# sudo mkdir /var/lib/tftpboot
	# sudo chmod -R 777 /var/lib/tftpboot
	# sudo chown -R nobody /var/lib/tftpboot

创建启动文件、准备镜像
prepare_ubuntu_iso
通过xinetd超级服务器启动tftpd

	# sudo service xinetd restart

这里没有使用start是因为，有可能已经安装了xinetd，要让新配置生效所以使用restart。如果全新安装restart命令也没有问题。
测试tftp服务
另一台计算机执行如下命令，get version.info是获取/var/lib/tftpboot/version.info文件，如果如下所示传输成功则tftp搭建成功。

	& tftp 192.168.1.133
	tftp> get version.info
	Received 60 bytes in 0.0 seconds
	tftp> quit

### 4.4 DHCP服务安装配置 ###

	# sudo apt-get -y install dhcp3-server

编辑 /etc/dhcp/dhcpd.conf 添加如下内容

	subnet 192.168.1.0 netmask 255.255.255.0 {
	  range 192.168.1.221 192.168.1.241;
	  option routers 192.168.1.1;
	  filename "pxelinux.0";
	}

上述配置依次指定了：
DHCP自动分配给客户端的IP地址范围为： 192.168.1.221 ~ 192.168.1.241
默认路由为192.168.1.1
需要传输的文件的文件名
启动DHCP服务

	# sudo service isc-dhcp-server start

### 4.5 客户端启动安装 ###
我使用VirtualBox虚拟机新建虚拟机，来测试PXE。局域网内的物理机一样操作。

- 当虚拟机启动时，取消镜像选择。
- 然后当出现下图时，按F12
- 按“l”键，选择从LAN启动
- 出现安装界面，直接 Enter
- ubuntu-pxe
- 然后正常安装到“choose a mirror ..”时，向上选择“ enter information manually”手动输入镜像位置
- ubuntu-pxe-mirror-choose
- 如下图直接输入：PXE服务器地址，本文为192.168.1.133
- ubuntu-pxe-mirror
- 这里是自动填写的
- ubuntu-pxe-mirror

### 4.6 参考 ###
http://digitalsanctum.com/2013/03/22/how-to-setup-a-pxe-server-on-ubuntu/
http://manpages.ubuntu.com/manpages/precise/en/man5/dhcpd.conf.5.html

## 5. 中文字符设置 ##
我们在安装ubuntu server版的时候，有人可能选择了中文环境安装，因为那样好设置时区等参数，可是安装好了后，运行某些命令的时候会有中文乱码提示，看起很是头蛋疼，我们就需要将其改成英文环境。我们需要修改的文件/etc/default/locale#sudo vim /etc/default/l...
我们在安装ubuntu server版的时候，有人可能选择了中文环境安装，因为那样好设置时区等参数，可是安装好了后，运行某些命令的时候会有中文乱码提示，看起很是头蛋疼，我们就需要将其改成英文环境。
我们需要修改的文件/etc/default/locale

	#sudo vim /etc/default/locale

中文设置为：

	LANG="zh_CN.UTF-8"
	LANGUAGE="zh_CN:zh"
	LANG="zh_CN.UTF-8"
	LANGUAGE="zh_CN:zh"

修改为：

	LANG="en_US.UTF-8"
	LANGUAGE="en_US:en"
	LANG="en_US.UTF-8"
	LANGUAGE="en_US:en"

将相应的zh改成en，将CN改成US即可，然后需要重启生效。

中文环境配置

配置中文环境，可以使系统提示的错误中文显示。
判断是否为中文环境的方法有：执行locale命令，有”zh_CN.UTF-8”
 
否则请安装中文环境，以ubuntu为例，步骤如下：

- 下载中文语言包：apt-get install language-pack-zh-hans-base
- 默认语言设置为中文：运行update-locale LANG=zh_CN.UTF-8和update-locale LANGUAGE=zh_CN.zh
- 重启系统：reboot，这样就变成中文环境了


## 6.VNC配置
### 6.1 安装桌面配合和VNC服务器
默认情况下，Ubuntu 16.04 Droplet没有安装图形桌面环境或VNC服务器，因此我们将开始安装它们。 具体来说，我们将为最新的Xfce桌面环境和官方Ubuntu存储库中提供的TightVNC软件包安装软件包。 

在您的服务器上，安装Xfce和TightVNC软件包。 

	$ sudo apt install xfce4 xfce4-goodies tightvncserver

要在安装完成后，VNC服务器的初始配置，使用vncserver命令来设置一个安全的密码。 

	$ vncserver

系统会提示您输入并验证密码，以及仅供查看的密码。 使用仅查看密码登录的用户将无法使用鼠标或键盘控制VNC实例。 如果您想向使用VNC服务器的其他人展示某些内容，但这不是必需的，这是一个有用的选项。 

运行vncserver完成通过创建默认的配置文件和连接信息为我们的服务器使用安装VNC的。 安装这些软件包后，现在可以配置VNC服务器了。

### 6.2 配置 VNC 服务器

首先，我们需要告诉我们的VNC服务器启动时要执行什么命令。 这些命令位于被称为一个配置文件xstartup在.vnc你的home目录下的文件夹中。 当您运行的启动脚本创建vncserver在上一步，但我们需要修改一些针对Xfce桌面的命令。 

VNC时首次设置，它在端口5901启动一个默认的服务器实例此端口被称为显示器端口，并通过VNC所提到的:1 。 VNC可以在其他显示器端口启动多个实例，如:2 ， :3 ，等等。当使用VNC服务器时，请记住:X是指显示器端口5900+X 。 

因为我们将改变VNC服务器的配置，我们需要先停止在端口5901上运行的VNC服务器实例。 

	$ vncserver -kill :1

输出应该看起来像这样，有一个不同的PID： 

	OutputKilling Xtightvnc process ID 17648

我们开始配置新的之前xstartup文件，让备份原件。 
	
	$ mv ~/.vnc/xstartup ~/.vnc/xstartup.bak

现在创建一个新xstartup使用文件nano或你喜欢的文本编辑器。 

	$ vim ~/.vnc/xstartup

将这些命令粘贴到文件中，以便在启动或重新启动VNC服务器时自动执行这些命令，然后保存并关闭文件。 

	~/.vnc/xstartup#!/bin/bash
	xrdb $HOME/.Xresources
	startxfce4 &

该文件中的第一个命令， xrdb $HOME/.Xresources ，讲述了VNC的GUI框架读取服务器用户.Xresources文件。 .Xresources是用户可以更改图形化桌面的某些设置，如终端的颜色，光标主题，和字体呈现。 第二个命令简单地告诉服务器启动Xfce，在这里你会找到所有的图形软件，你需要舒适地管理你的服务器。 

为确保VNC服务器能够正确使用此新启动文件，我们需要向其授予可执行权限。 

	$ sudo chmod +x ~/.vnc/xstartup

现在，重新启动VNC服务器。 
	
	$ vncserver

服务器应该使用类似于以下内容的输出启动： 

	OutputNew 'X' desktop is your_server_name.com:1
	
	Starting applications specified in /home/sammy/.vnc/xstartup
	Log file is /home/sammy/.vnc/liniverse.com:1.log

### 6.3 测试VNC桌面 

在此步骤中，我们将测试VNC服务器的连接性。 

首先，我们需要创建本地计算机上的SSH连接，能够安全地转发到localhost的VNC连接。 您可以通过以下命令在Linux或OS X上的终端执行此操作。 记得替换user和server_ip_address您的服务器的Sudo非root用户名和IP地址。 
ssh -L 5901:127.0.0.1:5901 -N -f -l username server_ip_address


如果您使用的是图形化的SSH客户端，如PuTTY，使用server_ip_address作为连接IP，并设置localhost:5901作为程序的SSH隧道设置的新的转发端口。 

接下来，你现在可以使用VNC客户端尝试在到VNC服务器的连接localhost:5901 。 系统将提示您进行身份验证。 要使用的正确密码是您在第1步中设置的密码。 

### 6.4 创建VNC服务文件 
接下来，我们将VNC服务器设置为systemd服务。 这将使其可以像任何其他systemd服务一样根据需要启动，停止和重新启动。 

首先，创建一个新的名为单元文件/etc/systemd/system/vncserver@.service用你喜欢的文本编辑器： 
	
	$ sudo nano /etc/systemd/system/vncserver@.service

将以下内容复制并粘贴到其中。 一定要改变PIDFILE的值用户的价值和用户名，以配合您的用户名。 

	/etc/systemd/system/vncserver@.service [Unit]
	Description=Start TightVNC server at startup
	After=syslog.target network.target
	
	[Service]
	Type=forking
	User=sammy
	PAMName=login
	PIDFile=/home/sammy/.vnc/%H:%i.pid
	ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
	ExecStart=/usr/bin/vncserver -depth 24 -geometry 1280x800 :%i
	ExecStop=/usr/bin/vncserver -kill :%i
	
	[Install]
	WantedBy=multi-user.target

保存并关闭文件。 

接下来，让系统知道新的单元文件。 

	$ sudo systemctl daemon-reload

启用单位文件。 

	$ sudo systemctl enable vncserver@1.service

停止VNC服务器的当前实例（如果它仍在运行）。 
	
	$ vncserver -kill :1

然后启动它，因为您将启动任何其他systemd服务。 
	
	$ sudo systemctl start vncserver@1

您可以验证它以此命令开始： 

	$ sudo systemctl status vncserver@1

如果它正确启动，输出应如下所示： 

输出 

	vncserver@1.service - TightVNC server on Ubuntu 16.04
	   Loaded: loaded (/etc/systemd/system/vncserver@.service; enabled; vendor preset: enabled)
	   Active: active (running) since Mon 2016-04-25 03:21:34 EDT; 6s ago
	  Process: 2924 ExecStop=/usr/bin/vncserver -kill :%i (code=exited, status=0/SUCCESS)
	...
	
	 systemd[1]: Starting TightVNC server on Ubuntu 16.04...
	 systemd[2938]: pam_unix(login:session): session opened for user finid by (uid=0)
	 systemd[2949]: pam_unix(login:session): session opened for user finid by (uid=0)
	 systemd[1]: Started TightVNC server on Ubuntu 16.04.

结论 

您现在应该有一个安全的VNC服务器启动并运行在您的Ubuntu 16.04服务器上。 现在，您将能够使用易于使用和熟悉的图形界面管理您的文件，软件和设置。 

## 7. Proxy
http://blog.sina.com.cn/s/blog_5397f28a0100p2c6.html


1.apt-get proxy 的配置

	sudo gedit /etc/apt/apt.conf 

NOTE：系统里有可能没有这个文件，直接建立一个就行
输入下面的proxy的配置信息就行

	Acquire::http::Proxy "http://username:password@address:port";

也可以增加ftp和https的proxy

	Acquire::ftp::Proxy "http://username:password@address:port";
	Acquire::https::Proxy "http://username:password@address:port";


2.terminal proxy 配置

	gedit ～/.bashrc
	输入下面的proxy的配置信息就行
	export http_proxy=http://username:password@address:port
	也可以增加ftp和https的proxy


3.UI的proxy设置

	点击 System -> Preferences -> Network Proxy
