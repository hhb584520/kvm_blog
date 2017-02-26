       
迁移包括系统整体的迁移和某个工作负载的迁移，在虚拟化环境中的迁移，又分为静态(static)迁移和动态迁移(live，也有少部分人称之为冷(cold)迁移和热(hot)迁移，或者离线(offline)迁移和在线(online)迁移.

动态迁移的好处：

- 负载均衡
- 解除硬件依赖
- 节约能源
- 实现客户机地理位置上的远程迁移

## 1. KVM 动态迁移原理和实践 ##
    
### 1.1 静态迁移 ###
       
a. (qemu) savevm my_tag    // 保存一个完整的客户机镜像快照（标记为 my_tag）
       
b. 在源主机关闭或暂停该客户机，然后将改客户机的镜像文件考不到另外一台宿主机中。
       
c. (qemu) loadvm my_tag

        
注意：
            
-  启动虚拟机命令要相同。
-  这种保存快照的方法需要 qcow2/qed等格式的磁盘镜像文件，因为只有它们才支持快照这个特性。
    
### 1.2 动态迁移 ###
         
不考虑磁盘存储复制的情况下，动态迁移大致的过程如下：
        
a. 在客户机动态迁移开始后，客户机依然在源宿主机上运行，与此同时，客户机的内存页被传输到目的主机之上。
        
b. Qemu/KVM 会监控并记录下迁移过程中所有已被传输的内存页的任何修改，并在所有的内存页都被传输完之后即开始传输在前面过程中内存页的更改的内容。
        
c. Qemu/KVM 会估计迁移过程中的传输速率，当剩余的内存数据量能够在一个可设定的时间周期（目前是30ms）内传输完成之时，Qemu/KVM 会关闭源主机上的客户机，再讲剩余的数据量传输到目的主机上去，最后传输过来的内存内容在目的宿主机上恢复客户机的运行状态。至此，KVM的一个动态迁移就完成了。

注意：

-  迁移过程中，尽量避免客户机中做内存使用非常大且修改频繁，如 Specjbb2005.
-  源和目的宿主机之间尽量用网络共享的存储系统来保存客户机磁盘镜像。且挂载位置必须完全相同。
-  尽量在同类型 CPU 的主机上面进行动态迁移。
-  64 位的客户机只能在 64 位宿主机之间迁移，而32 位客户机可以在32位宿主机和64位宿主机之间迁移。
-  动态迁移的源宿主机和目的宿主机对 NX(Never eXecute)位的设置是相同，要么同为关闭状态，要么同为打开状态。在Intel 平台上的 Linux 系统中，用 cat /proc/cpuinfo | grep nx 命令查看是否有 NX 的支持。
-  客户机名词必须唯一
-  目的宿主机和源宿主机的软件配置尽可能的相同，如都要配置相同的网桥，并让客户机以桥接的方式使用网络

## 2. 动态迁移的具体步骤 ##
### 2.1 NFS 作为共享存储 ###

1) 在源宿主机挂载 NFS的上客户机镜像，并启动客户机，命令行操作如下：

    # mount my-nfs:/rw-images/ /mnt
    # qemu-system-x86_64 /mnt/ia32e_rhel6u3.img -smp 2 -m 2048 -net nic -net tap
    
2) 在客户机上运行一个程序如top,  以便在动态迁移后检查它是否仍然正常地继续执行。
3) 目的宿主机上也挂载 NFS上的客户机镜像的目录，并且启动一个客户机用于接收动态迁移过来内存内容等

    # mount vt-nfs:/rw-images/ /mnt
    # qemu-system-x86_64 /mnt/ia32e_rhel6u3.img -smp 2 -m 2048 -net nic -net tap -incoming tcp:0:6666

4) 在源宿主机的客户机的 Qemu Monitor(Ctrl+Alt+2)中执行迁移命令

    (qemu) migrate tcp:vt-snb9:6666

5) 在本示例中，migrate 命令从开始到执行完成，大约用了十秒钟。在执行完迁移后，可以看到 top命令还在正常运行。

	Test steps:
	1. Create a vm1 in the Host1.
	   #  qemu-system-x86_64 -enable-kvm -m 2048 -smp 4  file=/share/xvs/var/rhel7.qcow, -monitor pty -cpu kvm64
	
	2. Start a TCP daemon for migration in the Host2.
	   #  qemu-system-x86_64 -enable-kvm -m 2048 -smp 4  file=/share/xvs/var/rhel7.qcow, -monitor pty -cpu kvm64 –incoming tcp:0:9999
	
	3. Execute migration in qemu monitor.
		# vncviewer # input vnc port
		# Ctrl+alt+2
	    # migrate –d –i tcp:<Host2 IP>:9999

注意：migrate_cancel 表示取消当前进行中的动态迁移过程

### 2.2 增量复制硬盘修改部分数据 ###
使用相同的后端镜像
    
1) 在源宿主机上，根据一个后端镜像文件，创建一个 qcow2格式的镜像文件，并启动客户机，命令行如下：

    # qemu-img create -f qcow2 -o backing_file=/mnt/ia32e_rhel6u3.img,size=20G rhel6u3.qcow2
    # qemu-system-x86_64 rhel6u3.qcow2 -smp 2 -m 2048 -net nic -net tap
    
2) 在目的宿主机上，也建立相同的 qcow2 格式的客户机镜像，并带有 “-incoming"参数来启动客户机使其处于迁移监控状态：

    # qemu-img create -f qcow2 -o backing_file=/mnt/ia32e_rhel6u3.img,size=20G rhel6u3.qcow2
    # qemu-system-x86_64 rhel6u3.qcow2 -smp 2 -m 2048 -net nic -net tap -incoming tcp:0:6666

3) 在源宿主机的客户机的 Qemu Monitor(Ctrl+Alt+2)中执行迁移命令

    (qemu) migrate -i tcp:vt-snb9:6666
    -i 表示 increasing，增量的，在迁移过程中，还有实时的迁移百分比显示。在目的机上也会显示迁移进度

注：由于 qcow2 文件中记录的增量较小（小于1GB），因此整个迁移过程花费了约 20 秒钟的时间。如果不使用后端镜像的动态迁移，将会传输完整的客户机磁盘镜像（可能需要更长时间），其步骤与上面类似，只有两点需要修改：一是不需要用创建 qcow2；二是Qemu Monitor中的动态迁移的命令变为 “migrate -b tcp:vt-snb9:6666” (-b参数意为 block，传输块设备)。

### 2.3 迁移命令 ###

    1) help migrate：
    2) help migrate_cancel：在动态迁移过程中取消迁移
    3) help migrate_set_speed ：设置动态迁移的最大传输速率
    4) help migrate_set_downtime ： 设置允许最大停机时间
    5) info migrate ：show migrate status

### 2.4 VT-d/SR-IOV 的动态迁移 ###

当 QEMU/KVM 中有设备直接分配到客户机中时，就不能对该客户机进行动态迁移，所以说 VT-d 和 SR-IOV 等会破坏动态迁移的特性。QEMU/KVM 并没有直接解决这个问题，不过可以使用热插拔设备来避免动态迁移的失效。我们可以在 qemu-system-x86_64启动虚拟机时候并不分配网卡给它，然后等客户机起来后，再动态添加网卡到客户机中使用。当客户机需要动态迁移时，就动态移除该网卡，待迁移完成后根据目的主机是否有来可供直接分配的网卡设备，如果有就动态分配给客户机。

另外，如果客户机使用较新的 Linux 内核，还可以使用"以太网绑定驱动”（Linux Ethernet Bonding driver），该驱动可以将多个网络接口绑定为一个逻辑上的单一接口。https://www.kernel.org/doc/Documentation/networking/bonding.txt .

如果使用 libvirt 来管理 QEMU/KVM，则在 libvirt0.9.2 以后中已经开始直接使用 VT-d 的普通设备和 SR-IOV的 VF 且不丢失动态迁移的能力。在 libvirt 中直接使用宿主机网络接口需要KVM宿主机中 macvtap 驱动的支持，要求宿主机的 Linux 内核是 2.6.38以后。在libvirt 的客户机的 XML 配置文件中，关于该功能的配置示例如下：

    <devices>
      ...
        <interface type='direct'>
          <source dev='eth0' mode='passthrough'/>
          <model type='virtio'/>
        </interface>
    </devices>
    







        