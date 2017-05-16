嵌套虚拟化（nested virtualization / recursive virtualization）是指在虚拟化的客户机中运行一个 Hypervisor，从而再虚拟化运行一个 Hypervisor. 嵌套虚拟化不仅包括相同 Hypervisor 的嵌套，也包括不同 Hypervisor的相互嵌套。

# 1. KVM 嵌套 KVM #

其中 L0(是Host OS)向 L1 提供硬件虚拟化环境（Intel VT），L1 向 L2 提供硬件虚拟化环境，以此类推。而最高级别的客户机 Ln 可以是一个普通客户机，不需要下面的 Ln-1 级想 Ln 级中的 CPU 提供硬件虚拟化支持。


KVM 对 “KVM嵌套KVM”的支持从 2010 年开始了，目前已经比较成熟了。有如下几个步骤：
1) 在 L0 中，加载 kvm-intel 模块时需要添加 “nested=1" 的选项打开 “嵌套虚拟化”的特性：

    # modprobe kvm
    # modprobe kvm_intel nested=1
    # cat /sys/module/kvm_intel/parameters/nested
        Y

2) 启动 L1 客户机时，在 qemu 命令中加上 "-cpu host" 或 "-cpu qemu64,+vmx" 选项以便将 CPU 的硬件虚拟化扩展特性暴露给 L1 客户机，如下：

    # qemu-system-x86_64 rhel6u3.img -m 4096 -smp 2 -net nic -net tap -cpu host

3) 在 L1 客户机中，查看 CPU 的虚拟化支持，然后加载 kvm 和 kvm_intel 模块，启动一个 L2 客户机，如下：

    # cat /proc/cpuinfo | grep vmx
    # modprobe kvm
    # modprobe kvm_intel
    # lsmod | grep kvm
    # qemu-system-x86_64 rhel6u3.img -m 4096 -smp 2

4) 在 L2 客户机中查看是否正常运行。


# 2. 参考资料 #

[NestedVirtualization.pdf](/kvm_blog/files/virt_others/NestedVirtualization.pdf)