# Linux 查看 BIOS 信息

做Linux系统底层的测试，有时候需要关注BIOS的信息（包括基本信息、检测到的CPU和内存等）。除了在开机启动时进入到BIOS之外，还可以在Linux系统中直接查看BIOS的信息，一般可以使用dmidecode命令（还有biosdecode命令可参考）；另外，在Windows中可以使用“DMIScope”软件（收费软件，笔者未使用过）来查看和修改BIOS。

SMBIOS (System Management BIOS)是主板或系统制造者以标准格式显示产品管理信息所需遵循的统一规范。
DMI (Desktop Management Interface, DMI)就是帮助收集电脑系统信息的管理系统，DMI信息的收集必须在严格遵照SMBIOS规范的前提下进行。
SMBIOS和DMI是由行业指导机构Desktop Management Task Force (DMTF)起草的开放性的技术标准；不过DMTF宣布DMI的生命期在2005年结束了。

使用dmidecode命令时，如果不加任何参数，则打印出所有类型的信息；而加上“-t type_num”或者“-t keywords”可以查看某个类型信息。

- dmidecode
- dmidecode -t 1
- dmidecode -t system


 
# SMBIOS specification #

    Type	Description
    0	BIOS Information
    1	System Information
    2	Baseboard (or Module) Information
    3	System Enclosure or Chassis
    4	Processor Information
    5	Memory Controller Information (Obsolete)
    6	Memory Module Information (Obsolete)
    7	Cache Information
    8	Port Connector Information
    9	System Slots
    10	On Board Devices Information
    11	OEM Strings
    12	System Configuration Options
    13	BIOS Language Information
    14	Group Associations
    15	System Event Log
    16	Physical Memory Array
    17	Memory Device
    18	32-Bit Memory Error Information
    19	Memory Array Mapped Address
    20	Memory Device Mapped Address
    21	Built-in Pointing Device
    22	Portable Battery
    23	System Reset
    24	Hardware Security
    25	System Power Controls
    26	Voltage Probe
    27	Cooling Device
    28	Temperature Probe
    29	Electrical Current Probe
    30	Out-of-Band Remote Access
    31	Boot Integrity Services (BIS) Entry Point
    32	System Boot Information
    33	64-Bit Memory Error Information
    34	Management Device
    35	Management Device Component
    36	Management Device Threshold Data
    37	Memory Channel
    38	IPMI Device Information
    39	System Power Supply
    40	Additional Information
    41	Onboard Devices Extended Information
    42	Management Controller Host Interface
    126	Inactive
    127	End-of-Table
    128-255	Available for system- and OEM- specific information
 

# 参考资料 #

http://en.wikipedia.org/wiki/System_Management_BIOS

http://en.wikipedia.org/wiki/Desktop_Management_Interface

http://www.joecen.com/2007/04/19/view-bios-operating-system-in-the-dmi-smbios-information/

Related posts:
Linux kernel启动参数
RedHat Linux 网络配置文件详解
Linux/Fedora17上DHCP和DNS服务器的配置方法和问题分析
更新Linux内核头文件(linux headers)