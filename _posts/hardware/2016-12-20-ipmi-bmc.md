# IPMI-BMC #

# 1. Get ipmitool ip #

    $ sudo ipmitool lan print 1  
    Set in Progress : Set Complete
    Auth Type Support   : MD5 PASSWORD
    Auth Type Enable: Callback : MD5 PASSWORD
    : User : MD5 PASSWORD
    : Operator : MD5 PASSWORD
    : Admin: MD5 PASSWORD
    : OEM  :
    IP Address Source   : DHCP Address
    IP Address  : 10.23.185.125
    Subnet Mask : 255.255.252.0
    MAC Address : 90:49:fa:01:2e:93
    SNMP Community String   : public
    IP Header   : TTL=0x00 Flags=0x00 Precedence=0x00 TOS=0x00
    BMC ARP Control : ARP Responses Enabled, Gratuitous ARP Disabled
    Gratituous ARP Intrvl   : 0.0 seconds
    Default Gateway IP  : 10.23.184.1
    Default Gateway MAC : 00:00:00:00:00:00
    Backup Gateway IP   : 0.0.0.0
    Backup Gateway MAC  : 00:00:00:00:00:00
    802.1q VLAN ID  : Disabled
    802.1q VLAN Priority: 0
    RMCP+ Cipher Suites : 0,1,2,3,4,6,7,8,9,11,12,13,15,16,17,18
    Cipher Suite Priv Max   : caaaaaaaaaaaaaa
    : X=Cipher Suite Unused
    : c=CALLBACK
    : u=USER
    : o=OPERATOR
    : a=ADMIN
    : O=OEM

# 2. We can use other machine to connect #
    
    $ ipmitool -I lanplus -U root -H (hz-bdw-bmc/ipaddr) sol activate
    $ ipmitool -I lanplus -U root -H (hz-bdw-bmc/ipaddr) -p 123456 sol activate(可以不用再次输入密码，直接使用)
    ------------------  deactivate ---------------------------------
    $ ipmitool -I lanplus -U root -H 192.168.101.108 sol deactivate

# 3. Enable it. #
    $ ipmitool -I lanplus -U root -H 192.168.101.108 sol activate
    Password:
    Info: SOL payload disabled
    
    ipmitool -I lanplus -H $bmcaddr -E sol set enabled true


# 4. Ref: #

http://wiki.drewhess.com/wiki/IPMI_and_SOL_on_an_Intel_S3200SHV

# 5. Problem #

## 5.1 Error activating SOL payload ##
    $ ipmitool -I lanplus -U root -P 123456 -H 192.168.102.207 sol activate
    Error activating SOL payload: Invalid data field in request
    解决方案：
    $ ipmitool -I lanplus -H 192.168.102.207 -U root -E sol set-in-progress enabled true
    Unable to read password from environment
    Password:
    $ ipmitool -I lanplus -H 192.168.102.207 -U root sol activate
    Password:
    [SOL Session operational.  Use ~? for help]

## 5.2 Unable to establish IPMI ##
    $ ipmitool -I lanplus -H 192.168.102.207 -E sol
    Unable to read password from environment
    Password:
    Error: Unable to establish IPMI v2 / RMCP+ session
    解决方案：
    加上要使用的用户比如root：-U root
