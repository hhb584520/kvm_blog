当然也可以直接下载集成好这些插件的包来，直接安装即可
http://www.eclipse.org/cdt/downloads.php

在目录：/usr/share/applications/ 添加 eclipse.desktop，将下面的内容写入，注意路径修改一下
  [Desktop Entry]
  Type=Application
  Name=Eclipse
  Comment=Eclipse Integrated Development Environment
  Icon=/eclipse_installpath/icon.xpm
  Exec=/eclipse_installpath/eclipse
  Terminal=false
  Categories=Development;IDE;Java;


## 1. 为什么要在Linux使用Eclipse ##
Linux是一个以C/C++开发为主的平台，无论是Kernel或是Application，主要都使用C/C++开发。传统在Linux下开发程序，是在文字模式下，利用vi等文字编辑器撰写C/C++程序存盘后，在Command line下使用gcc编译，若要debug，则使用gdb。

这种开发方式生产力并不高，若只是开发学习用的小程序则影响不大，但若要开发大型项目时，程序档案个数众多，需要用project或solution的方式管理；且debug时breakpoint的加入，单步执行，观察变量变化等，都需要更可视化的方式才能够增加生产力；最重要的，由于现在的程序语言皆非常的庞大，又有复杂的函式库，要程序员熟记所有的程序语法和function名称，实在很困难，所以语法提示(Intellisense)的功能就非常重要，这些就必须靠IDE来达成。

在Windows平台上，若要开发C/C++程序，我们有Microsoft Visual Studio、Borland C++ Builder可用，这些都是很好用的IDE，但可惜仅能在Windows下使用，但是在Linux平台呢?基于以下理由，我推荐使用Eclipse开发C/C++程序：

- Eclipse是一个用Java所撰写IDE，因此可跨平台，所以在Linux和Windows平台下皆可使用Eclipse，可降低程序员熟析IDE的学习曲线。
- Eclipse虽然主要拿来开发Java程序，但事实上Eclipse为一个『万用语言』的IDE，只要挂上plugin后，就可以在Eclipse开发各种语言程序，所以我们只要挂上CDT(C/C++ Development Toolkit)后，就可以在Eclipse开发C/C++程序，除此之外，目前的主流程序语言，如C/C++、C#、Java、PHP、Perl、Python、Ruby、Rebol、JavaScript、SQL、XML、UML等，皆可在Eclipse上撰写，所以只要熟析Eclipse的IDE环境，将来若开发其它语言程序，就不用再重新学习IDE环境了。
- 最重要的，Eclipse和CDT是Open Source且完全免费，取得相当容易，事实上Fedora 5已经包含Eclipse和CDT了，虽然预设Fedara 5安装时并没有含Eclipse，只要手动另外加选即可。

## 2.如何在Linux下安装Eclipse和CDT  ## 
### 2.1 下载档案 ###

    A、 下载JRE(Java Runtime Environment)。(http://java.sun.com/javase/downloads/index.jsp)
    B、 下载Eclipse SDK。(http://www.eclipse.org/downloads/)
    C、 下载CDT。(http://www.eclipse.org/cdt/downloads.php)

### 2.2 安装 ###

   A、安装JRE

      i. [root@localhost ~]#mkdir /usr/local/java
      ii. (将档案jre-1_5_0_09-linux-i586-rpm.bin下载到/usr/local/java目录下)
      iii. (超级用户模式)
      [root@localhost ~]#su            
      iv.  [root@localhost ~]#cd /usr/java
      v. (将您所下载的档的权限更改为可执行)
      [root@localhost java]#chmod a+x jre-1_5_0_09-linux-i586-rpm.bin
      vi. (启动安装过程)
      [root@localhost java]#./jre-1_5_0_09-linux-i586-rpm.bin
      (此时将显示二进制许可协议，按控格显示下一页，读完许可协议后，输入 『yes』继续安装。此时会将解压缩，产生jre-1_5_0_9-linux-i586.rpm)

      vii. (安装jre-1_5_0_9-linux-i586.rpm)
      [root@localhost java]#rpm –ivh jre-1_5_0_9-linux-i586.rpm

      (此时会将JRE装在/usr/java/jre1.5.0_09目录下)
      viii. (设定环境变量，让Linux能找到JRE)
      [root@localhost java]#vi /etc/profile
      (将以下内容加入在档案后面)
              1PATH = $PATH: / usr / java / jre1. 5 .0_09 / bin
              2export JAVA_HOME =/ usr / java / jre1. 5 .0_09
              3export CLASSPATH = $JAVA_HOME / lib:.
      (存盘后，重新启动Linux)
      ix. (测试Java是否安装成功)
      [root@localhost ~]#java –version

-------------------------------
JRE另外一种配置方法：
        vi /root/.bash_profile
        路径为 /usr/lib
              1PATH = $PATH: / usr / java / jre1. 5 .0_09 / bin
              2export JAVA_HOME =/ usr / java / jre1. 5 .0_09
              3export CLASSPATH = $JAVA_HOME / lib:.


   B、安装Eclipse SDK

      i. (将档案eclipse-SDK-3.2.1-linux-gtk.tar.gz下载到桌面)
      ii. [root@localhost ~]#cd /usr/local
      iii. [root@localhost local]#cp ~Desktop/eclipse-SDK-3.2.1-linux-gtk.tar.gz
      iv. (将eclipse-SDK-3.2.1-linux-gtk.tar.gz解压缩)
      [root@localhost local]#tar –zxvf eclipse-SDK-3.2.1-linux-gtk.tar.gz
      v. [root@localhost local]#cd eclipse
      vi. (执行Eclipse)
      [root@localhost eclipse]#./eclipse
      vii. (Select a workspace)
      (将Use this as the default and do not ask again打勾，以后就不会出现这个窗口)


      (第一次执行Eclipse会出现此error，因为没有任何Eclipse设定档，所以无法读取，第二次执行Eclipse就无此错误讯息，按OK继续。)


      (Eclipse主画面)


   C、安装CDT

      i. (将档案org.eclipse.cdt-3.1.1-linux.x86.tar.gz下载到桌面)
      ii. [root@localhost ~]#cp ~/Desktop/org.eclipse.cdt-3.1.1-linux.x86.tar.gz
      iii. (将org.eclipse.cdt-3.1.1-linux.x86.tar.gz解压缩)
      [root@localhost ~]#tar –zxvf org.eclipse.cdt-3.1.1-linux.x86.tar.gz
      (档案将解到~/eclipse目录下)
      iv. (安装CDT plugin)
      [root@localhost ~]cp –r eclipse/plugins/. /usr/local/eclipse/plugins/
      v. (启动Eclipse，多了C和C++ Project支持)

安装cdt，CDT 1.1 GA目前只支持Eclipse 2.1版。

将下载的包解压，会得到features和plugins这两个目录

[root@redarmy] unzip –d /opt org.eclipse.cdt-linux.gtk_1.1.0.bin.dist.zip

分别将这两个目录中的所有文件分别剪到/opt/eclipse下的对应目录里，即可。（Eclipse的插件安裝方法几乎都这样安装： 把文件下载后， 直接解到eclipse所安装的目录中对应的features和plugins中即可。）

## 3.安装Eclipse ##

### 3.1 安装 JDK ###
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

### 3.2 安装 Eclipse ###
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
   
# 4.如何在Eclipse上开发C/C++程序 #
## 4.1 建立Hello Word project ##
- 建立C/C++ project
- 选择Managed Make C++ Project(若选择Managed Make C++ Project，Eclipse会自动为我们建立make file；若选择Standard Make C++ Project，则必须自己写make file。)
- 输入Project name
- 选择Project类型(如执行档或Library，这里选择执行档即可)
- 额外的设定
- Open Associated Perspective?(选Yes继续)
- 建立C++ Source File
- 输入C++ Source File檔名
- 输入C++程序代码
- 执行程序(显示在下方的Console区)


## 4.2 如何在Eclipse CDT中Debug C/C++程序 ##
- 在Eclipse中Debug，就如同在一般IDE中Debug一样，只要在程序代码的左方按两下，就可加入breakpoint。
- 启动Debug
- Debug设定，按Debug开始Debug
- 单步执行，显示变量变化


# 5.结论 #
Eclipse为Linux在C/C++开发提供一个完善的IDE环境，事实上，以我用过众多IDE的经验，除了Visual Studio最方便外，Eclipse的好用也直追Visual Studio，并且超越Borland C++ Builder及Dev C++，虽然安装上比较麻烦，但只要依照本文介绍一步一步的设定，就一定可完成Eclipse设定，若想要在Windows平台使用gcc compiler，也建议使用Eclipse + CDT + MinGW的组合。