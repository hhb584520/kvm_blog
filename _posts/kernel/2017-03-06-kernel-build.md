## 1. Compile kernel ##
### 1.1 download code ###
	
	https://www.kernel.org/
	
	git clone git://vt-sync.sh.intel.com/linux.git

### 1.2 compile kernel ###	
	
	cd linux/
	cp /boot/config-* .config

    make -j 32
	make modules_install && make install

## 2. grub  ##
### 2.1 modify grub ###
 
under /etc/default/grub, append “console=tty0 console=ttyS0,115200 no_timer_check intel_iommu=on 3” to GRUB_CMDLINE_LINUX.

### 2,2 update grub ###
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

## 3. guest kernel compile ##

### 3.1 create build image ###
qemu-img create -f raw kernel_build.img 15G

### 3.2 create vm ###
$ vim xl.hvm

	builder = "hvm"
	name = "vm2"
	memory = 4096
	vcpus = 32
	vif = [ 'type=ioemu, mac=22:16:3e:10:9f:a7, bridge=xenbr0' ]
	disk = [ '/root/jl/pmu_xen.qcow2,qcow2,hda,rw', '/root/kernel.img,raw,hdb,rw' ]
	device_model_override = '/usr/local/lib/xen/bin/qemu-system-i386'
	device_model_version = 'qemu-xen'
	sdl=0
	vnc=1
	stdvga=1
	hap=1
	acpi=1
	gfx_passthru=0
	hpet=1
	serial='pty'

$ xl create xl.hvm

### 3.3 mount build disk ###

	mkfs.ext4 /dev/xvdb
	mount /dev/xvdb /root/xvdb
	cd /root/xvdb

then compile kernel

