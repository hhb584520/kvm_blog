# Ubunt 使用 #

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


## 2.安装源配置 ##
请注意：
如果在安装中部分软件无法安装成功，说明软件源中缺包，先尝试使用命令#apt-get update更新软件源后尝试安装。如果还是不行，需要更换软件源。更换步骤：

- 输入命令#cp /etc/apt/sources.list /etc/apt/sources.list_backup
- 输入命令#vi /etc/apt/sources.list
- 添加其他软件源（推荐使用163、中科大、上海交大等速度较快的国内源）
- 保存并关闭窗口
- 输入命令：#apt-get update

### 2.1 安装远程源 ###
for ubuntu14.04.4 source
 
gedit /etc/apt/sources.list

    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty main restricted
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty main restricted
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates main restricted
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates main restricted
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty universe
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty universe
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates universe
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates universe
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty multiverse
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-updates multiverse
    deb http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-backports main restricted universe multiverse
    deb-src http://linux-ftp.sh.intel.com/pub/mirrors/ubuntu/ trusty-backports main restricted universe multiverse

### 2.2 安装本地源 ###
第一步转到镜像的下载目录，挂载ISO镜像挂载至/media/cdrom下。
代码:
sudo mount -o loop -t iso9660 update-i386-20080312-CD1.iso /media/cdrom

第二步手动添加ISO镜像至软件源列表，这样就可以在软件库里找到ISO上所有的软件包
代码:
sudo apt-cdrom -m -d=/media/cdrom add

第三步刷新软件库
代码:
sudo apt-get update

注意，执行完成后查看/etc/apt/sources.list文件，确保文件如下一行在文件顶部或者在网络源前面，否者，安装软件的时候系统还是优先从网络上下载【建议把除了dvd本地源之外的下面所有项注视掉，不建议删除，之后在apt-get update更新下】
deb cdrom:[Ubuntu 9.04 _Jaunty Jackalope_ - Release i386 (20090421.3)]/ jaunty main restricted

之后就可以用apt-get install ** 来安装软件包了，不过有点问题，这命令执行一次可能会不成功，多执行几次就OK了

 

## 3.修改环境变量 ##
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

## 4.安装Eclipse ##

### 4.1安装 JDK ###
**下载JDK**

http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html

**卸载原来包**

If you’ve already installed OpenJDK in Ubuntu Software Center. Remove it by running this command:

    sudo apt-get purge openjdk*

**安装JDK**

Change directory to the location where you would like the JDK to be installed, then move the .tar.gz archive binary to the current directory.

Unpack the tarball and install the JDK.

% tar zxvf jdk-8uversion-linux-x64.tar.gz

**配置环境变量**

vim .bashrc
增加下面两行
export JAVA_HOME=/$unpack_dir/
export PATH=$PATH:/$unpack_dir/bin
You should use your path($unpack_dir) as per your installation
javac -version

**ref**
http://docs.oracle.com/javase/8/docs/technotes/guides/install/linux_jdk.html#BJFJJEFG

### 4.2安装 Eclipse ###
    $ mkdir -p /opt  
    $ cd /opt/  
    $ wget http://ftp.osuosl.org/pub/eclipse/technology/epp/downloads/release/mars/1/eclipse-cpp-mars-1-linux-gtk-x86_64.tar.gz
    
    $ tar -zxvf eclipse-cpp-mars-1-linux-gtk-x86_64.tar.gz
    $ cd eclipse
    $ vim /usr/share/applications/eclipse.desktop
		[Desktop Entry]
		Name=Eclipse 4
		Type=Application
		Exec=/opt/eclipse/eclipse
		Terminal=false
		Icon=/opt/eclipse/icon.xpm
		Comment=Integrated Development Environment
		NoDisplay=false
		Categories=Development;IDE;
		Name[en]=Eclipse

## 5. vncserver 配置 ##

用root账户名密码登陆后

1.在ubuntu上安装vncserver，使用命令：# apt-get install vnc4server

2.开启vnc服务，输入命令：#vncserver  
首次启动会要求设置密码，后面可以使用vncpasswd修改；
看到 New ‘****:1 (****)’ desktop is ****:1 (****代表主机名）即表示启动vnc成功，在主目录下产生一个.vnc目录；

3.在客户端下载“vnc客户端”软件，进行链接  
在服务器栏输入：ip：1  
输入用户名密码信息后，可以看到vnc连接页面  
但是，这个页面好像不是我们想要的图形化界面。vncserver默认使用的窗口管理器是twm，这是一个很简陋的窗口管理器，下面我们把桌面改成GNOME或KDE。

4.备份原有xstartup文件: #cp ~/.vnc/xstartup  ~/.vnc/xstartup.bak  
下面我们需要修改vnc启动文件，使用命令：#vi ~/.vnc/xstartup  

我们“x-window-manager &”这一行注释掉，然后在下面加入一行“gnome-session &”，或者是“startkde &”，分别启动GNOME桌面和KDE桌面。这里我们安装的是GNOME桌面。修改后如下图所示：（具体修改步骤：打开文件后，点击“insert”按钮，这时就可以输入了，在“x-window-manager &”前加“#”，然后回车输入“gnome-session &”，然后点击“Esc ”退出编辑模式，输入“:wq!”保存修改即可）

5.这时我们需要杀掉原桌面进程，输入命令：# vncserver -kill :1//这里的:1是桌面号  
再次输入： #vncserver :1生成新的会话

6.下面我们开始安装gnome桌面环境  
这里的安装有些慢，需要您耐心等待下。  
(1)安装x－windows的基础 ：#sudo apt-get install x-window-system-core

(2)安装登录管理器：#sudo apt-get install gdm （还可以为kdm/xdm）

(3)安装Ubuntu的桌面：#sudo apt-get install ubuntu-desktop（还可以为Kubunut-desktop/ Xubuntu-desktop ）

另外：  
安装命令：apt-get install gnome-core可以安装GNOME的一些基础。apt-get install firefox/gaim/xmms可以安装 Firefox 浏览器、Gaim 聊天程序、XMMS 音乐播放器。您可以按照自己的喜好来安装。
 
7.下面我们重复步骤5

8.编辑/etc/rc.local在文件最后一行加入：  
su root -c '/usr/bin/vncserver -name my-vnc-server -depth 16 -geometry 1280x800 :1'即可实现开机自启动

## 6. 配置开机启动服务 ##
### 6.1背景知识 ###
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

### 6.2启动步骤 ###
- 读取MBR信息，启动Boot Manager，Linux通常使用GRUB作为Boot Manager。
- 加载系统内核，启动init进程。init进程是Linux的根进程，所有的系统进程都是它的子进程。
- init进程读取/etc/inittab文件中的信息，并进入预设的运行级别。在这里需要说下的是，在ubuntu的6.10版本以后，就没有了/etc/inittab文件，是因为inittab已经被update软件包所取代了，具体的可以查看/usr/share/doc/update目录。就不在这里介绍了。
- 执行/etc/rcS.d/目录下的脚本，然后是/etc/rcX.d/目录下的脚本，X代表的是数字0～6。rcS.d和rcX.d目录下的文件都是以，S或K加上两位数字组成的，其中S代表start，K代表kill，而两位数字代表启动顺序，数字越大代表级别越低。

### 6.3设置开机启动项 ###

	$ apt-get install sysv-rc-conf
	$ sysv-rc-conf

它具有操作简单，简洁的操作界面，你可以使用鼠标点击，也可以使用键盘操作，空格键代表选择，“X”表示开启服务，Ctrl+N下一页，Ctrl+P上一页，Q退出。