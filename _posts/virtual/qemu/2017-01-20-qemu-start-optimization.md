**Before main()**

shared library loading: ldd /usr/local/bin/qemu-system-x86_64
init() routines: QEMU is heavily object-oriented

**Main()**

VCPU create : Cache CPUID result , initialize in parallel
Memory mapping : ACPI tables, Data for Virtual BIOS
Virtual Machine/devices initalization: Introduce pc-lite(主板) and remove unused devices.

**Virtual BIOS(delete--直接进到 kernel protected mode)**
https://github.com/bonzini/qboot

USE fw_cfg_dma instead of fw_cfg_io

**Bootloader**

**Kernel realmode code**

**Kernel protected mode code **

**Userspace**



Qemu start up  300ms --> 56ms