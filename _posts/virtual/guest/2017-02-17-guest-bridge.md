# 网桥 #

## 1. 添加接口到网桥 ##
- 添加 br0 这个 bridge
    
	brctl addbr br0

- 将 br0 与 eth0 绑定起来     
    
	brctl addif br0 eth0

- 将 br0 设置为启用 STP 协议
    
	brctl stp br0 on

    注：在这里使用 STP 主要是为了避免在建有 bridge 的以太网 LAN 中出现环路。如果不打开 STP，则可能出现数据链路层的环路，从而导致建有 bridge 的主机网络不畅通。

- 将 eth0 的 IP 设置为0
    
	dhclient br0

- 参看路由表是否正常配置
    
	route

## 2. 创建和删除网桥 ##
转载自：http://www.cnblogs.com/5201351/p/4445329.html

安装 KVM 后都会发现网络接口里多了一个叫做 virbr0 的虚拟网络接口

一般情况下，虚拟网络接口virbr0用作nat，以允许虚拟机访问网络服务，但nat一般不用于生产环境。我们可以使用以下方法删除virbr0

### 2.1 删除 virbr0 ###

1、先使用virsh net-list查看所有的虚拟网络：

[root@5201351 ~]# virsh net-list               //列出kvm虚拟网络


2、卸载与删除virbr0虚拟网络接口

[root@5201351 ~]# virsh net-destroy default    //重启libvirtd服务后会恢复
[root@5201351 ~]# virsh net-undefine default   //彻底删除，重启系统后也不会恢复
 

### 2.2 恢复virbr0的方法 ### 

1、其实上面的做法，其实就是删除了/var/lib/libvirt/network/default.xml文件，

恢复的方法，我们需要从另一台kvm宿主机上把default.xml文件复制过来，并将下面的<uuid>标签对及<mac>标签去掉。

	<!--
	WARNING: THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE 
	OVERWRITTEN AND LOST. Changes to this xml configuration should be made using:
	  virsh net-edit default
	or other application using the libvirt API.
	-->
	
	<network>
	  <name>default</name>
	  <uuid>ef1080c8-61d0-421e-8358-0568afb21093</uuid>
	  <forward mode='nat'/>
	  <bridge name='virbr0' stp='on' delay='0' />
	  <mac address='52:54:00:01:59:93'/>
	  <ip address='192.168.122.1' netmask='255.255.255.0'>
	    <dhcp>
	      <range start='192.168.122.2' end='192.168.122.254' />
	    </dhcp>
	  </ip>
	</network>

2、从一个xml文件定义default网络，执行如下命令：

[root@5201351 ~]# virsh net-define /var/lib/libvirt/network/default.xml   //从一个default.xml文件定义(但不开始)一个网络


3、设置virbr0自动启动，执行如下命令：

[root@5201351 ~]# virsh net-start default           //开始一个(以前定义的default)不活跃的网络,执行后ifconfig可见virbr0
[root@5201351 ~]# virsh net-autostart default       //执行后Autostart外会变成yes
 
