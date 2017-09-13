## 1.构建rpm 包
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

## 2. 怎样使用rpm命令一次性删除依赖的软件包 

搜索了一下网络，发现解法大体有两种：

### 2.1 第一种方法：不管依赖包

相互依赖的软件包，使用rpm的--nodeps参数就搞定了.  
rpm --nodeps -e gdm-2.24.1-4.fc10.i386

也就是说不检查依赖。这样的话，那些使用该软件包的软件在此之后可能就不能正常工作了。
 
### 2.2 第二种方法：手工添加依赖包到命令行

执行

	`rpm -e 要删除的rpm包名称`

然后根据输出再在命令行后面跟上依赖包名称

    `rpm -e 要删除的rpm包名称 依赖的rpm包名称`

这种方法是我以前也经常使用的，比如用于删除RHEL/CentOS中原装的jdk
 
下面演示这一步骤，比较烦，因为要删除的依赖包实在太多，要复制粘贴n次

    [root@localhost ~]# java -version
    java version "1.6.0_22" OpenJDK Runtime Environment (IcedTea6 1.10.4) (rhel-1.24.1.10.4.el5-i386) OpenJDK Server VM (build 20.0-b11, mixed mode)
    [root@localhost ~]# rpm -qa | grep jdk  
    java-1.6.0-openjdk-1.6.0.0-1.24.1.10.4.el5 java-1.6.0-openjdk-devel-1.6.0.0-1.24.1.10.4.el5
    [root@localhost ~]# rpm -e java-1.6.0-  openjdk-1.6.0.0-1.24.1.10.4.el5 java-1.6.0-openjdk-devel-1.6.0.0-1.24.1.10.4.el5
    error: Failed dependencies: jre >= 1.5.0 is needed by (installed) openoffice.org-ure-3.1.1-19.5.el5_5.6.i386
    [root@localhost ~]# rpm -e java-1.6.0-openjdk-1.6.0.0-1.24.1.10.4.el5 java-1.6.0-openjdk-devel-1.6.0.0-1.24.1.10.4.el5 openoffice.org-ure-3.1.1-19.5.el5_5.6.i386 error: Failed dependencies: libjvmaccessgcc3.so.3 is needed by (installed) openoffice.org-core-3.1.1-19.5.el5_5.6.i386 libjvmaccessgcc3.so.3(UDK_3.1) is needed by (installed) openoffice.org-core-3.1.1-19.5.el5_5.6.i386
    太多输出，省略
      by (installed) openoffice.org-calc-3.1.1-19.5.el5_5.6.i386 openoffice.org-ure = 1:3.1.1-19.5.el5_5.6 is needed by (installed) openoffice.org-graphicfilter-3.1.1-19.5.el5_5.6.i386 openoffice.org-ure = 1:3.1.1-19.5.el5_5.6 is needed by (installed) openoffice.org-draw-3.1.1-19.5.el5_5.6.i386
    [root@localhost ~]# 有太多软件包需要删除，此处不再继续
    [root@localhost ~]#
 
 
### 2.3 第三种方法：用脚本

编写一个 force_remove_package.sh 的Bash脚本，内容如下：

    #!/bin/sh  
      
    do_once()  
    {  
    	rpm -e "$@" 2>&1 | grep '(installed)'  
    }  
      
    for ((I=1; I<=4; ++I))  
    do  
    	DEPS="$DEPS $(do_once "$@" $DEPS | awk '{print $8}')"  
    	echo $I $DEPS  
    done  
 
其中，

- 用 for 循环进行有限次尝试 而不用 while true，那是为了防止编程死循环，别因为输入错误真的把系统里面所有的包都给删除了；  
- awk命令里面的 $8，是经过尝试出来的，因为 rpm -e 命令输出的信息中包含有很多空格；  
- rpm -e 的错误输出需要重定向到标准输出，否则就不会得到依赖包，而直接输出在终端上了。  

## 3. 制作 deb 包 ##
http://www.cnblogs.com/sunyubo/archive/2010/08/27/2282129.html
