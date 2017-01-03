## -sdl 参数 ##

        使用 SDL 方式显示客户机。

## -vnc 参数 ##

        -vnc localhost:2
	-name 设置显示方式
    设置客户机名称可用于在某宿主机上唯一标识该客户机，如“-name myname" 参数就表示设置客户机的名称为 myname.
	设置的名字将会在SDL窗口边框的标题显示，或者在VNC 窗口的标题栏中显示。

## -vga 参数 ##

        设置客户机中的 VGA 显卡类型，默认为 ”-vga cirrus” ，默认会为客户机模拟出 Cirrus Logic GD5446 显卡。“-vga std”会为客户机模拟出带有 Bochs VBE 扩展的标准 VGA显卡，而“-vga none” 参数是不为客户机分配 VGA 卡，会让 VNC或SDL都没有任何显示。

## -nographic 参数 ##
        完全关闭 QEMU 的图形化界面输出，从而让 QEMU 在模式下完全成为简单的命令行工具。而QEMU中模拟产生的串口被重定向到了当前的控制台中，所以如果在客户机中对其内核进行配置从而让内核的控制台输出重定向到串口后，就依然可以在非图形模式下管理客户机系统。
        在非图形模式下，使用 Ctrl+a h(按Ctrl+a 之后，再按h 键) 组合键，可以获得终端命令的帮助
串口设置
http://0pointer.de/blog/projects/serial-console.html

新的可以采用
-display sdl
-display vnc
-display none
-display curses

不带图形显示
修改 guest /boot/grub2/grub.conf

- sudo mount ia32e_rhel7u2_kvm.img -o offset=1048576 /mnt
- fdisk -l ia32e_rhel7u2_kvm.img
	
	Disk rhel7u2_kvm.img: 21.5 GB, 21474836480 bytes, 41943040 sectors
	Units = sectors of 1 * 512 = 512 bytes
	Sector size (logical/physical): 512 bytes / 512 bytes
	I/O size (minimum/optimal): 512 bytes / 512 bytes
	Disk label type: dos
	Disk identifier: 0x000e5f14

    Device Boot      Start         End      Blocks   Id  System
	rhel7u2_kvm.img1   *        2048     1026047      512000   83  Linux
	rhel7u2_kvm.img2         1026048    41943039    20458496   8e  Linux LVM

- mount ia32e_rhel7u2_kvm.img -o offset=1048576 /mnt
- vim /mnt/grub2/grub.conf
    
	change "rhgb quiet" to "console=ttyS0,115200,8n1"

- umount /mnt
- create guest
	sudo /usr/local/bin/qemu-system-x86_64 -enable-kvm -m 8192 -smp 1 -hda /home/berta/ia32e_rhel7u2_kvm.img -cpu kvm64 -nographic


