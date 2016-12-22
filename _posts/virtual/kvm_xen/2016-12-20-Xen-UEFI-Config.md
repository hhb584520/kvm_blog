# 配置XEN的 UEFI 启动 
以下是在UEFI模式下安装的OS中适用
（install UEFI 模式的OS：先在bios中Boot Maintence Manager-->Advanced Boot Options,把Boot Mode改为UEFI，然后正常安装OS就行了）

安装完OS后，以下是配置xen启动项的步骤：  
1.从http://vmm-qa.sh.intel.com/vmm_data/suites/function/html/index-xen.php?arch=ia32e 上下载一个xen rpm包 
 
2.rpm -ivh 安装下载的xen rpm 包

3.在/boot/efi/EFI/redhat路径下新建一个xen.cfg文件（刚开始是没有的，可以从别的UEFI OS copy 一个）
    $ vim xen.cfg
    [global]
    default=xen
    
    [xen]
    options=dom0_mem=4096M dom0_max_vcpus=4 loglvl=all guest_loglvl=all unrestricted_guest=1 msi=1 console=com1,115200,8n1 sync_console hap_1gb=1 conring_size=128M psr=cmt psr=cat psr=cdp ept=pml cpufreq=performance vpid=1
    kernel=vmlinuz-xen ro root=/dev/mapper/rhel-root console=hvc0,115200,8n1
    ramdisk=initrd-xen.img


4.打开xen.cfg文件，把里面的root等于号后面的信息（参考native启动项）改为与该机器grub.cfg中native启动项中root等于号后的信息。

5.reboot->BIOS->Boot Maintence Manager-->Advanced Boot Options-->Add EFI Boot Option，然后按几次Enter，会看到EFI-->redhat，然后会看到xen.efi

6.选中xen.efi，Enter，输入你要起的名字，保存退出。
 
7.在change boot order中会看到刚才添加的xen4.8,然后把它调为第一启动，保存退出。

8.这时机器会重启，当看到下图所示时，就可以了


在OS中执行/etc/init.d/xencommons start，然后执行xl list 来判断xen启动是否配好。
