# Redhat 使用 #

## 1.redhat update ## 
### 1.1 配置 /etc/yum.repo.d/ 源 ###

$ cat linux-ftp.repo  
[rhel$releasever]  
name=Red Hat Enterprise Linux $releasever  
baseurl=http://linux-ftp.sh.intel.com/pub/ISO/redhat/redhat-rhel/RHEL-7.3-Snapshot-4/Server/x86_64/os/  
enabled=1  
gpgcheck=0  

[rhel6_optional]  
name=Red Hat Enterprise Linux rhel6_optional  
baseurl=http://linux-ftp.sh.intel.com/pub/ISO/redhat/redhat-rhel/RHEL-7.3-Snapshot-4/Server-optional/x86_64/os/  
enabled=1  
gpgcheck=0  


执行 update
	# yum update
	
### 1.2 配置本地 yum 源 ###

本文配置本地yum源是把RedHat 7的系统盘内容复制到服务器硬盘的目录/RH7ISO中，然后配置yum指向该目录。



- 首先挂载光驱到/mnt目录 ：mount /dev/cdrom /mnt
- 复制系统盘的内容到/rhel7iso目录中：cp -R /mnt/* rhel7iso
- 进入yum配置目录 : cd /etc/yum.repos.d/ 
- 建立yum配置文件: touch  rhel7_iso.repo 
- 编辑配置文件，添加以下内容: vim rhel7_iso.repo 

    [RHEL7ISO]
    name=rhel7iso  
    baseurl=file:///rhel7iso  
    enabled=1  
    gpgcheck=1  
    gpgkey=file:///rhel7iso/RPM-GPG-KEY-redhat-release  

- 清除yum缓存: yum clean all 
- 缓存本地yum源中的软件包信息: yum makecache 

配置完毕！可以直接使用yum install packname进行yum安装了！

## 2.RedHat7下NFS服务搭建##
http://www.idcyunwei.org/post/32.html

## 3.构建rpm 包
http://www.bkjia.com/Linuxjc/994106.html
针对该文档，需要修改 下载源码到 BUILD目录，最后 %files 去掉，这是我实践的一个结果

	vim nginx.spec
	
	  1 Name: nginx
	  2 Summary: high performance web server
	  3 Version: 1.2.1
	  4 Release: 1.e15.ngx
	  5 License: 2-clause BSD-like license
	  6 Group: Applications/Server
	  7 Source: http:/nginx.org/download/nginx-1.2.1.tar.gz
	  8 URL: http://nginx.org/
	  9 Distribution: Linux
	 10 Packager: huanghaibin <haibin.huang@intel.com>
	 11
	 12 %description
	 13 nginx is a HTTP and reverse proxy server, as well as a mail proxy server.
	 14
	 15 %prep
	 16 rm -rf $RPM_BUILD_DIR/nginx-1.2.1
	 17 zcat $RPM_BUILD_DIR/nginx-1.2.1.tar.gz | tar -xvf -
	 18
	 19 %build
	 20
	 21 cd nginx-1.2.1
	 22 ./configure --prefix=/usr/local/nginx
	 23
	 24 make
	 25
	 26 %install
	 27 cd nginx-1.2.1
	 28 make install
	 29
	 30 %preun
	 31 if [ -z "`ps aux | grep nginx | grep -v grep`" ];then
	 32     killall nginx >/dev/null
	 33     exit 0
	 34 fi
	 35

## 4.Install redhat ##

### 4.1 Install with GUI ###


### 4.2 Install without GUI ###