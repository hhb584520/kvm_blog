# Suspend to memory(S3)  # 

    /usr/libexec/qemu-kvm -name 'xx' -m xG -smp `cat /proc/cpuinfo | grep "processor" | wc -l` -cpu host_model_name -M pc-i440fx-rhel7.2.0/pc-i440fx-rhel7.3.0/q35 -boot order=c,once=c,menu=on -no-kvm-pit-reinjection -enable-kvm  -drive file=/path/guest-image,index=0,if=none,id=drive-virtio-disk1,media=disk,cache=none,format=qcow2,aio=native -device virtio-blk-pci,bus=pci.0,addr=0x5,drive=drive-virtio-disk1,id=virtio-disk1,scsi=off -device virtio-net-pci,netdev=idKaeUOu,mac=9a:68:5a:f1:4b:7d,id=ndev00idKaeUOu,bus=pci.0,addr=0x3 -netdev tap,id=idKaeUOu,vhost=on-monitor stdio -vnc :0	

Suspend guest to mem for linux guest  
    $ echo mem >/sys/power/state  
 	 

# Suspend to disk(S4) #
	/usr/libexec/qemu-kvm -name 'xx' -m xG -smp `cat /proc/cpuinfo | grep "processor" | wc -l` -cpu host_model_name -M rhel6.5.0 -boot order=c,once=c,menu=on -no-kvm-pit-reinjection -enable-kvm-drive file=/path/guest-image,index=0,if=none,id=drive-virtio-disk1,media=disk,cache=none,format=qcow2,aio=native -device virtio-blk-pci,bus=pci.0,addr=0x5,drive=drive-virtio-disk1,id=virtio-disk1,scsi=off -device virtio-net-pci,netdev=idKaeUOu,mac=9a:68:5a:f1:4b:7d,id=ndev00idKaeUOu,bus=pci.0,addr=0x3 -netdev tap,id=idKaeUOu,vhost=on-monitor stdio -vnc :0	1. Boot guest

Suspend guest to disk  
	$ echo disk >/sys/power/state  
	$ powercfg -h on
	 	 