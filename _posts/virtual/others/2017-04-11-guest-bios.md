## 1. BIOS ##
SeaBIOS 代码已经合入 Qemu， 采用的 Qemu
OVMF 是 UEFI BIOS


## 2. -bios  指定客户机的BIOS文件 ##

设置 BIOS 的文件名称。一般来说，qemu-kvm 会到 ”/usr/local/share/qemu/“ 目录下去找 BIOS文件。
但也可以使用 ”-L path“ 参数来改变 qemu-kvm 查找 BIOS/VGA BIOS/keymaps 等文件的目录。

qemu-system-x86_64 -m 4096 -monitor pty -serial stdio -hda /root/rhel7u2_kvm.qcow2  -device virtio-net-pci,netdev=nic0,mac=00:16:3e:6f:5d:ea -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup --enable-kvm -M kernel-irqchip=split -bios /root/bios.bin -smp cpus=288 -device intel-iommu,intremap=on,eim=on -machine q35

## 3. OVMF
### 3.1 introduction
https://www.linux-kvm.org/page/OVMF

http://www.linux-kvm.org/downloads/lersek/ovmf-whitepaper-c770f8c.txt

OVMF is a project to enable UEFI support for Virtual Machines.

### 3.2 how to do
Step1:Run command:  Directory=$(pwd)

Step2:Download sorce code: 

	git clone git://vt-sync/ovmf.git

Step3:install  package dependency:

	yum install  iasl nasm  gcc (version>4.4)

Step4:Modify config file:

	cd  $Directory/ovmf/Conf
	vim target.txt   modify ACTIVE_PLATFORM and  TARGET_ARCH
  		ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgIa32X64.dsc
  		TARGET_ARCH           = IA32 X64

Step5:Build OVMF:

	make -C $Directory /ovmf/BaseTools/Source/C
	cd $Directory /ovmf/
	OvmfPkg/build.sh  -a X64

Step6.	Find ovmf firmware:
	
	find  / -name  OVMF*  2>&1 |grep –v "Permission"
		$Directory /ovmf/Build/OvmfX64/DEBUG_GCC48/FV/OVMF_VARS.fd
		$Directory /ovmf/Build/OvmfX64/DEBUG_GCC48/FV/OVMF_CODE.fd
		$Directory /ovmf/Build/OvmfX64/DEBUG_GCC48/FV/OVMF.fd

Step7:Create guest

    Eg: qemu-img create  -f raw  /home/redhat7u2.img

	qemu-system-x86_64 -enable-kvm -cpu host -m 4028 -smp 4 -boot order=cd -hda /home/redhat7u2.img -cdrom /RHEL7u2.iso -vnc :6 -usb -usbdevice tablet -bios $Directory/ovmf/Build/OvmfX64/DEBUG_GCC48/FV/OVMF.fd

Step8.Check Result

启动后进入 BIOS，进入 Boot Manager 查看，可以看到 UEFI BIOS


