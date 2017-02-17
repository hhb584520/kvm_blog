# SPICE #

# 1. 介绍 #
## 1.1 参考文档 ##
主页：https://www.spice-space.org/index.html

代码分析：http://blog.csdn.net/hbsong75/article/details/9749497

## 1.2 介绍
SPICE(独立计算环境简单协议)是一个开源的远程计算机解决方案，提供客户端访问远程显示和设备（例如: 键盘、鼠标、音频）。Spice提供一个桌面用户体验，而将最大限度的减轻客户端的CPU和GPU任务。
        
Spice的组成基本模块如下：

- Spice协议
- Spice服务器
- Spice客户端
- 下面的图显示了VDI接口

当前该项目的主要聚焦于提供高质量的远端访问QEMU的虚拟机，寻找帮组打破虚拟适配层的障碍通过克服传统的桌面虚拟化的挑战。为了这个目的，RedHat引入了SPICE协议，它被用于SPICE的客户端和服务端通信。其它组件开发包括QXL显示设备和驱动等等。



# 2. 环境搭建 #

## 2.1 Client
spice-gtk是一个GTK+2和GTK+3 SPICE小部件，它是一个基于glib开发的对象，主要用于解析SPICE协议。该小部件（SPICE显示）被嵌入到另外应用程序中，如virt-manager，通过 Python绑定也是可用的。我们通过是将 SPICE GTK小部件嵌入在 virt-viewer中，我们强烈建议使用 virt-viewer。 

Linux: SPICE GTK+ Widget - spice-gtk-0.22.tar.bz2，virt-viewer - virt-viewer-0.5.7.tar.gz
Windows：virt-viewer Windows installer - 64 bit - virt-viewer-x64-0.5.7.msi

### 2.1.1 Linux下使用SPICE客户机 ###
    
	#yum -y install spice-client
    
    Linux 下使用spicec命令连接：
    # /usr/libexec/spicec -h 192.168.0.13 -p 5930 -w password
        -h 参数是kvm虚拟机ip地址
        -p参数是kvm虚拟机端口
        -w参数是密码
        
### 2.1.2 Windows下使用SPICE客户机 ###
    
	从 http://www.spice-space.org/download.html 下载如下文件：，然后安装即可
    virt-viewer-x64-0.5.7.msi
    在安装目录的bin目录下找到 remoteviewer.exe运行就可以了


## 2.2 Server ##
### 2.2.1 CentOS 6/RHEL6  ###

这里是直接修改配置文件方式，首先安装软件包: #yum -y install spice-server
然后建立一个普通名称是web的虚拟机，可以使用virt-manager虚拟机管理工具和命令行两种方法。下面编辑虚拟机文件添加spice参数：

	~# virsh edit web
	<domain type='kvm'>
	.....
	  <devices>
	    <emulator>/usr/libexec/qemu-kvm</emulator>
	    <interface type='bridge'>
	.....
	    </interface>
	
	# add
	<graphics type='spice' port='5930' autoport='no' listen='192.168.0.13 ' passwd='password'/> 
	  <video>
	    <model type='qxl' vram='32768' heads='1'/>
	    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
	    </video>
	    <memballoon model='virtio'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
	    </memballoon>
	  </devices>
	</domain>
	#add之后是需要添加的部分。然后保存文件。

启动虚拟机：
	
	#virsh start web
		Domain web started

启动虚拟机后，修改配置文件，添加#add之后的内容：

	virsh edit web
	# add following lines
	# for slot='xxxx', set an empty number
	<sound model='ac97'>
	  <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
	</sound>

重启web虚拟机

	# virsh start web
	Domain www started

### 2.2.2 Fedora 16 ###
这里是使用命令行的方式，首先安装软件包：

	#yum -y install spice-protocol spice-server xorg-x11-drv-qxl

这里使用命令行方式，下面是一个windows的例子

	#virt-install \
	-n windows \
	-r 2048 \
	-f /var/kvm/images/windows.img \
	-s 50 \
	--vcpus=2 \
	--os-type windows \
	--os-variant=win7 \
	--network bridge=br0 \
	--graphics spice,port=5930,listen=192.168.0.13,password=password \
	--video qxl \
	--channel spicevmc \
	--cdrom /dev/cdrom

使用virt-manager配置Spice的方法

virt-manager是基于libvirt 的图像化虚拟机管理软件，请注意不同的发行版上 virt-manager的版本可能不同，图形界面和操作方法也可能不同。本文使用了 CentOS 6上的virt-manager。首先建立一个虚拟机，最后一步选择“在安装前自定义配置”选项提供一些高级自定义配置。


启动virt-manager打开你的虚拟机。
单击虚拟硬件的详细信息。删除VNC。然后选择添加硬件新增一个图形设备，类型选择spice server，端口号可以在增加spice server的时候设置。如果选择自动分配，那么会从5900开始递增分配。
下面将原来视频中使用的虚拟显卡换成我们需要的视频卡QXL设备。点击视频并在型号下拉选择QXL类型。
这样启动虚拟机之后，就可以使用spice了。

### 2.2.3 通常的安装方法 ###
当我们构建支持QEMU的SPICE时，SPICE的 Server代码是需要，它应该可以从一个linux发布的包中获得，这种方式是最好的获得方式
SPICE - Server spice-0.12.4.tar.bz2
spice-protocol - headers defining protocols, spice-protocol-0.12.6.tar.bz2
libusbredir - For USB redirection support.

**Guest**
这部分包含各种可选驱动和后台程序，它能够被安装到Guest中，用来提高虚拟机的性能，主要包括两大部分，一个是代理一个是驱动，驱动又包括显卡驱动和IO口的驱动。

**Linux安装**

SPICE vdagent - spice-vdagent-0.15.0.tar.bz2

x.org QXL video driver - xf86-video-qxl-0.0.17.tar.bz2; Also contains Xspice

**Windows安装**

Windows guest tools - spice-guest-tools-0.65.1.exe，This installer contains some optional drivers and services that can be installed in Windows guest to improve SPICE performance and integration. This includes the qxl video driver and the SPICE guest agent (for copy and paste, automatic resolution switching, ...)

##2.4.附录 ##
### 2.4.1 Build and Install SPICE-GTK on Ubuntu ###

http://huang.yunsong.net/2012/spice-gtk-ubuntu.html

### 2.4.2 红帽的虚拟桌面：手把手教你安装配置SPICE服务 ###

http://os.51cto.com/art/201201/311464.htm

