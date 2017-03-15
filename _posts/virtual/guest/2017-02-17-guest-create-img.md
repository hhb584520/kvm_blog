# 1. install from iso #

## 1.1 download iso ##
  wget http://linux-ftp.sh.intel.com/pub/ISO/redhat/redhat-rhel6/RHEL-7.2-GA/Server/x86_64/iso/RHEL-7.2-20151030.0-Server-x86_64-dvd1.iso

## 1.2 create vm ##

	qemu-img create -f raw rhel7u2_console.img 25G

	qemu-system-x86_64 -enable-kvm -m 4096  -smp 4 \
	-boot order=cd -hda ./rhel7u2_console.img \
	-cdrom /haibin/img/linux/RHEL-7.2-20151030.0-Server-x86_64-dvd1.iso \
	-net nic,model=virtio,mac=00:16:3e:17:d8:99 -net tap,script=/etc/kvm/qemu-ifup \
	-daemonize


## 1.3 install OS ##

**Language**

select English-->English(United States)

**Software Selection**

select Basic Web Server

- Directory Client
- Guest Agents
- Network file system client
- Performance tools
- Python
- Compatibility Libraries
- Development tools

**Installation Destination**

I will configure partitioning

**Begin Installation**

Set Root Password

## 1.4 start vm ##

qemu-system-x86_64 -enable-kvm -m 4096  -smp 4 -hda ./rhel7u2_console.img -net nic,model=virtio,mac=00:16:3e:17:d8:99 -net tap,script=/etc/kvm/qemu-ifup

