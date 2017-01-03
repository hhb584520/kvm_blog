## 1. BIOS ##
SeaBIOS 代码已经合入 Qemu， 采用的 Qemu
OVMF 是 UEFI BIOS


## 2. -bios  指定客户机的BIOS文件 ##

设置 BIOS 的文件名称。一般来说，qemu-kvm 会到 ”/usr/local/share/qemu/“ 目录下去找 BIOS文件。
但也可以使用 ”-L path“ 参数来改变 qemu-kvm 查找 BIOS/VGA BIOS/keymaps 等文件的目录。

qemu-system-x86_64 -m 4096 -monitor pty -serial stdio -hda /root/rhel7u2_kvm.qcow2  -device virtio-net-pci,netdev=nic0,mac=00:16:3e:6f:5d:ea -netdev tap,id=nic0,script=/etc/kvm/qemu-ifup --enable-kvm -M kernel-irqchip=split -bios /root/bios.bin -smp cpus=288 -device intel-iommu,intremap=on,eim=on -machine q35
