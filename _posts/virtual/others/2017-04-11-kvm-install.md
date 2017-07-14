# 1. Config Hardware #

http://www.thomas-krenn.com/en/wiki/Activating_the_Intel_VT_Virtualization_Feature

## 1.1 Open VT-x and VT-d 

	Intel(R) Virtualization Technology
	Intel(R) VT for Directed I/O

## 1.2 Confirm Hardware Configure ##

	cat /proc/cpuinfo | grep -E '(vmx|svm)'


# 2. Install KVM #
## 2.1 Base KVM RPM package ##

	rpm -e kvm
	rpm -ivh kvm*.rpm

## 2.2 Base Source Code ##
### 2.2.1 Download Source Code ###
**For External**

	$ git clone git://git.kernel.org/pub/scm/virt/kvm/kvm.git   
	$ git clone git://git.qemu-project.org/qemu.git

**For Internal**

	$ git clone git://vt-sync/kvm.git   
	$ git clone git://vt-sync/qemu.git	
	

### 2.2.2 Compile KVM  ###
 
- copy config to linux
	
	cp [config_for_kvm](/kvm_blog/files/virt_others/config_for_kvm) .config

comments:
 if you debug, you want just compile kvm.ko and kvm_intel.ko

	make -j8 -C `pwd` M=`pwd`/arch/x86/kvm modules
	http://www.10tiao.com/html/625/201702/2652501984/1.html

**we also don't need to check**

- Check the kernel Configure
	
	$ make menuconfig
	choose "Virtualization" and configure as follows

		x x--- Virtualization   x x
		x x<M>   Kernel-based Virtual Machine (KVM) support x x
		x x<M> KVM for Intel processors support x x
		x x< > KVM for AMD processors support   x x
		x x[*] Audit KVM MMUx x
		x x<M>   Host kernel accelerator for virtio net (EXPERIMENTAL)  

- check .config file in directory of kvm.git
    	
		CONFIG_HAVE_KVM=y
		CONFIG_HAVE_KVM_IRQCHIP=y
		CONFIG_HAVE_KVM_EVENTFD=y
		CONFIG_KVM_APIC_ARCHITECTURE=y
		CONFIG_KVM_MMIO=y
		CONFIG_KVM_ASYNC_PF=y
		CONFIG_HAVE_KVM_MSI=y
		CONFIG_VIRTUALIZATION=y
		CONFIG_KVM=m 
		CONFIG_KVM_INTEL=m
		# CONFIG_KVM_AMD is not set
		CONFIG_KVM_MMU_AUDIT=y

### 2.2.3 Complie new kernel and install ###
	
a. after installed the kernel, vmlinuz and initrafms are generated under boot directory	or maybe you can use anthor way to build this module. 
		
		# make olddefconfig
		# make -j 32 #-j is a parameter
		# make modules_install && make install

b. check /boot/grub/grub.conf, a option of grub is added
	
	menuentry 'Red Hat Enterprise Linux Server (4.5.0-rc4-12695-g0fb00d3) 7.2 (Maipo) with debugging' --class fedora --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulin
	
	ux-kvm-advanced-6afe35ac-ecf2-438b-83db-f3da76c2e709' {
	        load_video	
	        insmod gzio	
	        insmod part_msdos	
	        insmod ext2	
	        set root='hd0,msdos3'	
	        if [ x$feature_platform_search_hint = xy ]; then	
	          search --no-floppy --fs-uuid --set=root --hint-bios=hd0,msdos3 --hint-efi=hd0,msdos3 --hint-baremetal=ahci0,msdos3 --hint='hd0,msdos3'  6afe35ac-ecf2-438b-83db-f3da76c2e709	
	        else	
	          search --no-floppy --fs-uuid --set=root 6afe35ac-ecf2-438b-83db-f3da76c2e709	
	        fi	
	        linux16 /boot/vmlinuz-4.5.0-rc4-12695-g0fb00d3 root=UUID=6afe35ac-ecf2-438b-83db-f3da76c2e709 ro BOOT_IMAGE=/boot/vmlinuz-kvm root=UUID=6afe35ac-ecf2-438b-83db-f3da76c2e709 ro crashkernel=a	
	uto rhgb quiet intel_iommu=on LANG=en_US.utf8 systemd.log_level=debug systemd.log_target=kmsg	
	        initrd16 /boot/initramfs-4.5.0-rc4-12695-g0fb00d3.img
	
	}

c. Reboot and boot into updated kernel

- Build qemu.git  
    `# git clone git://vt-sync/qemu.git qemu.git   ## clone qemu repo under `  
    `# cd qemu.git`   

- you can check which branch of qemu   
    `# git branch`

- you can checkout to uq/master tree
    
	`# git checkout uq/master`
    
- then compile the qemu  
    
		$ ./configure --target-list=x86_64-softmmu  
	    $ ./configure --target-list=x86_64-softmmu --enable-kvm --enable-vnc --disable-gtk --disable-sdl # -display sdl
	    Comments: Ctrl+Alt+2 --> info kvm 查看是否编译时候使用了 --enable-kvm  
	    $ make   
	    $ make install  


		[root@kbl-sgx qemu-sgx-master]# ./configure
		
		ERROR: DTC (libfdt) version >= 1.4.0 not present. Your options:
		         (1) Preferred: Install the DTC (libfdt) devel package
		         (2) Fetch the DTC submodule, using:
		             git submodule update --init dtc 
		下载一份 dtc 到 qemu 目录下就好了
		$ git clone http://git.qemu.org/git/dtc.git 

-  after qemu is installed, check kvm module
    
		$ lsmod | grep kvm  
	    	kvm_intel 128177  0   
	    	kvm   413542  1 kvm_intel  
	    	If KVM modules is not loaded, load the modules manually  
	    $ modprobe kvm  
	    $ modprobe kvm_intel  

# 3. Create guest #
## 3.1 Create a guest #
	$ qemu-img create -b /share/xvs/img/linux/ia32e_rhel7u2_ga.img -f qcow2 /root/rhel7u2.qcow2  
	$ qemu-system-x86_64  -m 1024 -smp 4 -net nic,macaddr=xx.xx.xx.xx.xx.xx -net tap,script=/etc/kvm/qemu-ifup -hda /root/rhel7u2.qcow2 -display sdl  
	when guest is boot up,you can check kvm status in qemu monitor  
	$ctrl+alt+2        ####switch to qemu monitor  
	info kvm
	if kvm is disable, you must add parameter "-enable-kvm" when you create guest.
	$ qemu-system-x86_64 -enable-kvm -m 1024 -smp 4 -net nic,macaddr=xx.xx.xx.xx.xx.xx -net tap,script=/etc/kvm/qemu-ifup -hda /root/rhel7u2.qcow2

## 3.2 Create Image
	$ dd if=/dev/zero of=sles12.img bs=1M count=10240
    or 
	qemu-img create ...
	$ qemu-system-x86_64 -m 2048 -smp 4 -boot order=cd -hda sles12.img -cdrom sles12.iso
	$ qemu-system-x86_64 -m 2048 -smp 4 -hda sles12.img 

## 3.3 安装虚拟机管理工具
　　apt-get install virt-manager  

# 4. Problem  #
## 4.1 No Enough Virtual Disk Space

	环境配置：对于sda/vda等格式的硬盘　　
	OS：centos 6.1　　
	虚拟机的属性：domainname   test　　Disk path   /var/lib/libvirt/images/test.img　　
	   硬盘分区：df -hT　　
	FilesystemTypeSize Used Avail Use% 
	Mounted on　　/dev/vda1 ext46.8G 3.2G 3.3G 50% 
	/tmpfstmpfs499M 0 499M   0% 
	/dev/shm　　需要添加硬盘空间。　
　
### 4.1.1 添加磁盘 
    既然是少一块硬盘，那么我们就直接给虚拟机加一块硬盘就好了，然后直接挂载到根分区的一个目录下面。这样我根分区的硬盘空间就扩展了。　　
    具体步骤：
    A，生成一块新的硬盘，使用virt-manager很容易，直接在虚拟的属性中点击“添加硬件”----“storage”选择多大的空间，驱动类型，缓存模式。然后点击完成。注意，有些硬盘是支持热插拔的，有些不支持。除了IDE格式的硬盘外，其他的都支持热插拔，这就意味着，如果添加的是IDE的硬盘的话，需要对虚拟机进行重启，使他识别新添加的硬盘。
    如果采用virsh命令添加的话。
    $ qemu-img create -f raw test_add.img 10G　　//说明，生成一块新的raw格式的空盘
    $ virsh attach-disk test /var/lib/libvirtd/images/test_add.img vdb —cache none　　
    或者#virsh edit test 在xml中的disk后面添加如下几行。　　
    <disk type='file' device='disk'>　　
    <driver name='qemu' type='raw' cache='none'/>　　
    <source file='/var/lib/libvirt/images/test_add.img'/>
    <target dev='vdb' bus='virtio'/>
    </disk>　　
     B，在虚拟机中对硬盘进行格式化
     登录到虚拟机中，首先查看是否能新识别硬盘　　
     $ fdisk -l 查看是否回显示新添加的硬盘/dev/vdb　　然后，对vdb进行格式化，　　
     $ mkfs.ext4 /dev/vdb　　接下来，新建一个目录用来挂载新的硬盘　　
     $ mkdir   /test　　
     $ mount /dev/vdb /test　　最后，将该挂载添加到开机启动中　　
     $ blkid /dev/vdb   //获取硬盘的UUID　　
    	/dev/vdb: UUID="19fc1d1d-7891-4e22-99ef-ea3e08a61840" TYPE="ext4"　　
     $ vim /etc/fstab 
    	添加开机加载，在最后一行加入　　UUID=19fc1d1d-7891-4e22-99ef-ea3e08a61840 /test ext4 defaults1 2　

### 4.1.2 直接拉升分区
        
采用挂载的方法是而外添加了一块盘，有没有一种方法可以直接对硬盘进行拉伸。qemu-img中提供了一个resize的命令，但是该命令只是单纯的简单了拉升或者缩小了一个raw的img镜像大小，对于其中的分区却不能进行修改。我需要对其中的的分区进行拓展。很碰巧红帽子提供这种插件可以时间。此方法是采用红帽子自带的插件virt-resize进行拓展。该命令首先是获取原来的分区信息，还有其他文件信息。然后对新的镜像进行重新分区、格式化。最后拷贝原镜像中的文件到新文件系统中，再用新拓展的镜像替换原有镜像。因为实际采用copy的方式，所以他花的时间比较长，如果是一个大镜像不建议使用此方法，具体解决方案。  

    前提安装libguestfs-tools工具包。关闭虚拟机　　#yum -y install libguestfs-tools　　 
    A，新建一个大镜像　　
    	$ qemu-img create -f raw test_extend.img 15G　　注意，这里的img大小是你需要拓展的总大小
    B，使用virt-resize进行拉升分区　　
    	$ virt-resize —expand   /dev/vda1 /var/lib/libvirt/images/test.img /var/lib/libvirt/images/test_new.img
    注意，此时间很长，请耐心等待　　
    C．使用新扩展的镜像代替原镜像　　
		$ mv /var/lib/libvirt/images/test_new.img /var/lib/libvirt/images/test.img
    D，启动虚拟机　　
		$ virsh start test　　
		virt-resize的优势:能对虚拟机中的特定的分区进行拓展。并且能够拓展windows镜像。不需要登录到虚拟机里面进行任何操作。　
		缺点：拓展的时候需要关机。对于大的镜像，拓展的时间比较长。
	　　对于LVM格式的虚拟机，如果你的硬盘格式支持LVM。那么你的硬盘拓展将容易许多，LVM支持硬盘的在线扩容。
	　　方法步骤：
    		$ lvcreate -L 40G -n lv_vm_test1 VolGroup　　
    		$ virsh attach-disk test /dev/mapper/VolGroup/lv_vm_test vdb
		 　　注意，有可能碰到权限问题。请先修改/dev/mapper/VolGroup/lv_vm_test的权限，是虚拟机可以挂载。
		进入虚拟机的操作：
			$ pvcreate /dev/vdb　　
			$ vgextend VolGroup /dev/vdb　　
			$ vgs　　#lvextend -l +100%FREE /dev/VolGroup/lv_root　　
			$ resize2fs -p /dev/VolGroup/lv_root　　
			优势：拓展时间很快，支持动态扩展。　　缺点，不适合window的拓展。 


