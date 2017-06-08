# 1. Source Install #
## 1.1 Install dependency Package ##
yum install libaio-devel yajl yajl-devel libuuid-devel dev86 iasl glibc.i686 glib2 glib2-devel glibc-devel trousers trousers-devel SDL-devel pciutils-devel mercurial ncurses-devel openssl-devel  curl-devel pixman-devel nss* nmap* -y 

## 1.2 Create Directory 
- [root@vt]#cd /   
- [root@vt]#mkdir /home/build
- [root@vt]#cd /home/build    
- [root@vt build]#git clone git://vt-sync.sh.intel.com/xen.git

## 1.3 Compile
[root@vt-ivt1  build]#cd xen

**modify the config disk type: xvda--->hda**

	sed -i '/disk/s/xvda/hda/g' tools/examples/xlexample.hvm
	sed -i '/disk/s/xvda/hda/g' tools/examples/xlexample.pvlinux

**Update the context inside**  
Update the context inside "GIT_HTTP"'s else branch:'OVMF_UPSTREAM_URL', ‘QEMU_UPSTREAM_URL’, 'QEMU_TRADITIONAL_URL',  ‘SEABIOS_UPSTREAM_URL’, 'MINIOS_UPSTREAM_URL'setting.

	sed -i 's$OVMF_UPSTREAM_URL ?=.*$OVMF_UPSTREAM_URL=git://vt-sync/ovmf.git$' ./Config.mk
	sed -i 's$QEMU_TRADITIONAL_URL ?=.*$QEMU_TRADITIONAL_URL=git://vt-sync/qemu-xen-traditional.git$' ./Config.mk
	sed -i 's$QEMU_UPSTREAM_URL ?=.*$QEMU_UPSTREAM_URL ?= git://vt-sync/qemu-xen.git$' ./Config.mk
	sed -i 's$SEABIOS_UPSTREAM_URL ?=.*$SEABIOS_UPSTREAM_URL ?= git://vt-sync/seabios.git$' ./Config.mk
	sed -i 's$MINIOS_UPSTREAM_URL ?=.*$MINIOS_UPSTREAM_URL ?= git://vt-sync/mini-os.git$' ./Config.mk
	sed -i 's/3403ac4313812752be6e6aac35239ca6888a8cab/2e11d582b5e14759b3c1482d7e317b4a7257e77d/' ./Config.mk

**Export http_proxy**  
[root@vt xen]# export http_proxy="http://proxy-shz.intel.com:911"   #Update the proxy server which is available to you, make sure it can  connect to “http://xenbits.xen.org”. If the proxy changed , the url should be updated.

[root@vt xen]# export GIT_HTTP="y"

**Excute configure** 

[root@vt xen]#./configure  #default

If you want boot a OVMF guest, you can enable the Ovmf option like this:  
[root@vt xen]#./configure --enable-ovmf

**Make xen**  

	[root@vt xen]#make xen -j $num_cpu  # ‘-j $num_cpu’ 
	. Make tools, install xen & tools  
	[root@vt xen-unstable.hg]#make tools -j $num_cpu  
	[root@vt xen-unstable.hg]#make install-xen  
	[root@vt xen-unstable.hg]#make install-tools 
	. Verify. After finishing installing xen & tools, new files are generated in /boot directory
	[root@vt xen-unstable.hg]#cd /boot 
	[root@vt-ivt1 boot]#ll -tr 
	
	-rw-r--r--. 1 root root 13313173 May 24 21:19 xen-syms-4.6-unstable 
	-rw-r--r--. 1 root root   793467 May 24 21:19 xen-4.6-unstable.gz 
	lrwxrwxrwx. 1 root root       19 May 24 21:19 xen-4.6.gz -> xen-4.6-unstable.gz 
	lrwxrwxrwx. 1 root root       19 May 24 21:19 xen.gz -> xen-4.6-unstable.gz 

## 1.4 Download and build dom0 ##
### 1.4.1 Download linux.git ###

	[root@vt boot]#cd /home/build/ 
	[root@vt build]#git clone git://vt-sync.sh.intel.com/linux-stable.git  
	. Down latest kernel config file, and rename it to /home/build/linux/.config config-3.9.3--its a example configure file

### 1.4.2 Make Linux kernel ###
	[root@vt build]#scp xen-build.sh.intel.com:/home/build/repo/config-example linux-stable/.config 
	[root@vt build]#cd linux-stable 
	[root@vt linux-stable]#echo "" | make oldconfig  
	[root@vt linux-stable]#make -j 32 
	[root@vt linux-stable]#make modules_install  
	[root@vt linux-stable]#make install  
	. Verify. After finishing installing dom0, new files are generated in /boot directory
	[root@vt linux]cd /boot 
	[root@vt boot]ll -tr 
	-rw-r--r--. 1 root root  5084960 May 24 22:26 vmlinuz-4.1.1
	-rw-r--r--. 1 root root  2483412 May 24 22:26 System.map-4.1.1 
	lrwxrwxrwx. 1 root root       20 May 24 22:26 vmlinuz -> /boot/vmlinuz-4.1.1
	lrwxrwxrwx. 1 root root       23 May 24 22:26 System.map -> /boot/System.map-4.1.1 
	-rw-r--r--. 1 root root  4863943 May 24 22:26 initramfs-4.1.1.img 

### 1.4.3 Modify configurations ###
Edit /boot/grub/grub.conf, one new grub for native Linux is as follow:

	title Red Hat Enterprise Linux (2.6.32-431.el6.x86_64)         
	root (hd0,0)         
	kernel /boot/vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=aacf436a-d293-4e69-a43d-e5de0348bcdd 3 console=ttyS0,115200,8n1         
	initrd /boot/initramfs-2.6.32-431.el6.x86_64.img 

	The grub ‘Red Hat Enterprise Linux Server (3.9.3)’ is auto generated when install Linux kernel. Then add grub ‘xen-32e’ as follows:
	[root@knl1 ~]# cat /boot/grub/grub.conf
	default=0timeout=5splashimage=(hd0,0)/grub/splash.xpm.gz
	hiddenmenu
	title Xen-4.7
	    root (hd0,0)
	    kernel /xen.gz dom0_mem=4096M loglvl=all guest_loglvl=all unrestricted_guest=1 msi=1 console=com1,115200,8n1 sync_console hap_1gb=1 conring                                                                      _size=128M psr=cmt psr=cat
	    module /vmlinuz-xen ro root=/dev/mapper/vg_knl1-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_LVM_LV=vg_knl1/lv_root rd_NO_MD SYSFONT=latarcyrheb-                                                                      sun16 crashkernel=auto rd_LVM_LV=vg_knl1/lv_swap  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet,115200,8n1
	    module /initrd-xen.img
	title Red Hat Enterprise Linux 6 (2.6.32-573.el6.x86_64)
	    root (hd0,0)
	    kernel /vmlinuz-2.6.32-573.el6.x86_64 ro root=/dev/mapper/vg_knl1-lv_root rd_NO_LUKS LANG=en_US.UTF-8 rd_LVM_LV=vg_knl1/lv_root rd_NO_MD SY                                                                      SFONT=latarcyrheb-sun16 crashkernel=auto rd_LVM_LV=vg_knl1/lv_swap  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet
	    initrd /initramfs-2.6.32-573.el6.x86_64.img


### 1.5 Download and Compile Qemu ###

For qemu-upstream-unstable.git:

	./configure --target-list=i386-softmmu  --enable-xen --enable-xen-pci-passthrough
	make -j8
	make install

NOTE: It'll install to /usr/local/ by default
For qemu.git

NOTE: you may need to build xen and xen tools first.
Please add following two lines in xen configuration file:

	device_model_override = '/usr/local/bin/qemu-system-i386'
	device_model_version = 'qemu-xen'

NOTE: ‘device_module_override’ indicates the directory your qemu binary is installed in.

# 2. RPM Install #

	# wget http://vmm-build.sh.intel.com/curia/xen-unstable_75da1b15_20170219-1.x86_64.rpm
    # rpm -ivh xen-unstable_75da1b15_20170219-1.x86_64.rpm

# 3. Verify #
## 3.1 Reboot the system ##
Reboot the system, start system via ‘xen-32e’ grub entry, and login. . Start xencommons.

	[root@vt /]#echo "/usr/local/lib" >>/etc/ld.so.conf
	[root@vt /]#ldconfig
	[root@vt /]# /etc/init.d/xencommons start 
	we also can put 3 command to /etc/rc.d/rc.local, then give rc.local execute(chmod +x /etc/rc.d/rc.local)

## 3.2 Create VM ##
.Verify whether xen works via ‘xl list’ and ‘xl info’ command, correct display is follows:

	[root@vt-ivt1 ~]# xl list
	Name                                        ID   Mem VCPUs      State   Time(s)
	Domain-0                                     0  4095    32     r-----   15918.0
	
	[root@ localhost /]# xl info 
	host                   : vt-ivt1
	release                : 4.1.0
	version                : #1 SMP Mon Jun 29 14:48:41 CST 2015
	machine                : x86_64
	nr_cpus                : 32
	......
	
	[root@ localhost /]# xl create rhel7.conf

## 3.3 Create Bridge ##

	eth0 config
	[root@knl2 network-scripts]# cat ifcfg-eth0
	DEVICE=eth0
	TYPE=Ethernet
	UUID=dbe2f97c-fe08-4a4d-925a-a409b49e543d
	ONBOOT=yes
	NM_CONTROLLED=no
	BOOTPROTO=none
	HWADDR=00:1E:67:F9:AA:40
	DEFROUTE=no
	PEERDNS=yes
	PEERROUTES=yes
	IPV4_FAILURE_FATAL=yes
	IPV6INIT=no
	NAME="System eth0"
	BRIDGE=xenbr0
	
	br0 config
	[root@knl2 network-scripts]# cat ifcfg-xenbr0
	DEVICE=xenbr0
	TYPE=Bridge
	ONBOOT=yes
	NM_CONTROLLED=no
	BOOTPROTO=dhcp
	IPV4_FAILURE_FATAL=yes
	IPV6INIT=no

### 3.4 Guest Serial ###
**KVM** 

	$qemu-system-x86_64 -m 512 -smp 2 -hda /path/to/your/image -serial pty
	$cat /dev/pts/$num

**Xen**

vm config 
	
	serial='pty'

grub

    delete "rhgb quiet"
    add "console=ttyS0,115200,8n1"
 
how to use
	
	xl console domid

# 4. Problem #
## 4.1 xl list ##

	[root@skl-2s1 ~]# xl list
	xencall: error: Could not obtain handle on privileged command interface: No such file or directory
	libxl: error: libxl.c:108:libxl_ctx_alloc: cannot open libxc handle: No such file or directory
	cannot init xl context

Maybe you don't boot xen, please check grub

## 4.2 ksmtuned not found ##
/usr/sbin/ksmtuned: line 66: /sys/kernel/mm/ksm/run: No such file or directory

the cited bug is due to the fact that ksmtuned is not compatible with Xen currently, which is why you simply should turn it off. Do this via "chkconfig ksmtuned off" and reboot. This error should be gone then. 

