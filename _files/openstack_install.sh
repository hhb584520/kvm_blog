#!/bin/bash
set +e

#openstack version
OPENSTACK_VER=4.8

ControlServAddr=localhost
DBServer=localhost
NovaComputNetInterface=eth1
NovaComputManagerInterface=eth0
#nova manager dhcp use interface
NovaCtrlNetInterface=eth2
LibVirtCpuModel=SandyBridge
IS_MASTER_INSTALL=yes

ADMIN_PASSWORD=intple
KEYSTONE_HOST=$ControlServAddr
RabbitmqServer=$ControlServAddr
KeystoneServer=$ControlServAddr
GlanceServer=$ControlServAddr
QuantumServer=$ControlServAddr
# if db node does not exist with control ,DBServer need config currect
QuantumMetadataServer=$ControlServAddr
NovametaServer=$ControlServAddr
#CinderServer=$ControlServAddr
TargetVolume=/dev/sdb

# back log max size,unit M
LOG_BACK_MAX_SIZE=100
# back log record max num, over limited will drop
LOG_BACK_NUM=3
# back log task run time, rangth 0-23 
LOG_BACK_TIME=1

export OS_SERVICE_TOKEN="ADMIN"
export OS_SERVICE_ENDPOINT="http://${KeystoneServer}:35357/v2.0"
KEYSTONE_REGION=RegionOne



function install_deps()
{
    #echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main" > /etc/apt/sources.list.d/grizzly.list
    #apt-get update
    #apt-get -y --force-yes upgrade
    apt-get install -y --force-yes ntp
    apt-get install -y --force-yes nfs-kernel-server

}

function install_db()
{
        export LANG=UTF-8
    apt-get install -y --force-yes  ntp python-mysqldb mysql-server
    sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
    service mysql restart
}

function install_db_client()
{
    apt-get install -y --force-yes  python-mysqldb
}

function drop_db(){
    mysql -u root -pintple <<EOF
DROP DATABASE nova;
DROP DATABASE keystone;
DROP DATABASE glance;
DROP DATABASE cinder;
DROP DATABASE quantum;
EOF
} 

function configure_db()
{
   echo "input db password:"
mysql -u root -pintple <<EOF
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY "$ADMIN_PASSWORD";
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY "$ADMIN_PASSWORD";
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY "$ADMIN_PASSWORD";
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY "$ADMIN_PASSWORD";
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY "$ADMIN_PASSWORD";
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY "$ADMIN_PASSWORD";
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY "$ADMIN_PASSWORD";
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY "$ADMIN_PASSWORD";
CREATE DATABASE quantum;
GRANT ALL PRIVILEGES ON quantum.* TO 'quantum'@'localhost' IDENTIFIED BY "$ADMIN_PASSWORD";
GRANT ALL PRIVILEGES ON quantum.* TO 'quantum'@'%' IDENTIFIED BY "$ADMIN_PASSWORD";
FLUSH PRIVILEGES;
EOF
}

function install_mq()
{
    apt-get install -y --force-yes rabbitmq-server
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/rabbitmq-server
}

function install_keystone()
{
    apt-get install -y --force-yes keystone python-keystone python-keystoneclient
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/keystone
}

function configure_keystone()
{
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/keystone/keystone.conf
    # modify nova auth fail bug, from https://bugs.launchpad.net/devstack/+bug/1071926
    sed -i "s/#token_format = PKI/token_format = UUID/"   /etc/keystone/keystone.conf
    sed -i "s/DBServer/${DBServer}/"       /etc/keystone/keystone.conf
    if [[ $IS_MASTER_INSTALL == 'yes' ]]; then
    keystone-manage db_sync
    fi
    service keystone stop
}


function install_glance()
{
    apt-get install -y --force-yes glance glance-api glance-registry python-glanceclient glance-common
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/glance-api
    touch /etc/scaleone/guard_list/glance-registry
}

function configure_glance()
{
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/glance/glance-api.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/glance/glance-registry.conf
    sed -i "s/DBServer/${DBServer}/"           /etc/glance/glance-api.conf
    sed -i "s/DBServer/${DBServer}/"           /etc/glance/glance-registry.conf
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"   /etc/glance/glance-registry.conf
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"   /etc/glance/glance-api.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"   /etc/glance/glance-api.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"   /etc/glance/glance-registry.conf
    service glance-api restart
    service glance-registry restart
    if [[ $IS_MASTER_INSTALL == 'yes' ]]; then
    glance-manage db_sync
    fi
    service glance-api stop
    service glance-registry stop
}


function install_compute_server()
{
    apt-get install -y --force-yes nova-api nova-cert nova-common nova-conductor nova-scheduler python-nova python-novaclient
    apt-get install qemu-utils -y --force-yes
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/nova-api
    touch /etc/scaleone/guard_list/nova-scheduler
    touch /etc/scaleone/guard_list/nova-conductor
}

function configure_compute_server()
{
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/nova/nova.conf
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"   /etc/nova/nova.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/nova/api-paste.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/nova/api-paste.ini
    sed -i "s/GlanceServer/${GlanceServer}/"         /etc/nova/nova.conf
    sed -i "s/QuantumServer/${QuantumServer}/"  /etc/nova/nova.conf
    sed -i "s/DBServer/${DBServer}/"  /etc/nova/nova.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/nova/nova.conf
    sed -i "s/QuantumMetadataServer/${QuantumMetadataServer}/"  /etc/nova/nova.conf
    sed -i "s%^libvirt_cpu_model=.*$%libvirt_cpu_model=$LibVirtCpuModel%g" /etc/nova/nova.conf
    service nova-api stop
    if [[ $IS_MASTER_INSTALL == 'yes' ]]; then
    nova-manage db sync
    fi
    service nova-api stop
    service nova-scheduler stop
    service nova-conductor stop
    echo "cgroup_device_acl = [
                              \"/dev/null\", \"/dev/full\", \"/dev/zero\",
                              \"/dev/random\", \"/dev/urandom\",
                              \"/dev/ptmx\", \"/dev/kvm\", \"/dev/kqemu\",
                              \"/dev/rtc\", \"/dev/hpet\", \"/dev/net/tun\"
                              ]" >> /etc/libvirt/qemu.conf
}


function install_cinder_server()
{
    #apt-get install -y --force-yes  cinder-api cinder-scheduler cinder-volume open-iscsi python-cinderclient tgt
    apt-get install -y --force-yes  cinder-api cinder-scheduler cinder-volume python-cinderclient 
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/cinder-api
    touch /etc/scaleone/guard_list/cinder-scheduler
    touch /etc/scaleone/guard_list/cinder-volume
}

function configure_cinder_server()
{

    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   		/etc/cinder/api-paste.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"    /etc/cinder/api-paste.ini
	
	sed -i "s/MyPassword/${ADMIN_PASSWORD}/"        /etc/cinder/cinder.conf
	sed -i "s/DBServer/${DBServer}/"                /etc/cinder/cinder.conf

	# Add Rabbit Server
	#1.rabbit_host = 12.0.0.202
	sed -i '$a\rabbit_host=RabbitmqServer'          /etc/cinder/cinder.conf
	sed -i "s/RabbitmqServer/${RabbitmqServer}/"    /etc/cinder/cinder.conf
	#2.rabbit_password = intple
	sed -i '$a\rabbit_password = MyPassword'        /etc/cinder/cinder.conf
	sed -i "s/MyPassword/${ADMIN_PASSWORD}/"        /etc/cinder/cinder.conf
	#3.rabbit_hosts = 12.0.0.202:5672
	sed -i '$a\rabbit_hosts=RabbitmqServer:5672'    /etc/cinder/cinder.conf
	sed -i "s/RabbitmqServer/${RabbitmqServer}/"    /etc/cinder/cinder.conf
	#rabbit_userid = guest
	sed -i '$a\rabbit_userid = guest'               /etc/cinder/cinder.conf
	
    #sed -i 's/false/true/g' /etc/default/iscsitarget
    #service iscsitarget start
    #service open-iscsi start
    if [[ $IS_MASTER_INSTALL == 'yes' ]]; then
    cinder-manage db sync
    fi
    service cinder-api stop
    service cinder-scheduler stop
    service cinder-volume stop
}

function install_cinder_backend()
{
    apt-get install -y --force-yes cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient linux-headers-`uname -r` 
}

function configure_cinder_backend()
{
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   		/etc/cinder/api-paste.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"    /etc/cinder/api-paste.ini

	sed -i "s/MyPassword/${ADMIN_PASSWORD}/"        /etc/cinder/cinder.conf
	sed -i "s/DBServer/${DBServer}/"                /etc/cinder/cinder.conf

	# Add Rabbit Server
	#1.rabbit_host = 12.0.0.202
	sed -i '$a\rabbit_host=RabbitmqServer'          /etc/cinder/cinder.conf
	sed -i "s/RabbitmqServer/${RabbitmqServer}/"    /etc/cinder/cinder.conf
	#2.rabbit_password = intple
	sed -i '$a\rabbit_password = MyPassword'        /etc/cinder/cinder.conf
	sed -i "s/MyPassword/${ADMIN_PASSWORD}/"        /etc/cinder/cinder.conf
	#3.rabbit_hosts = 12.0.0.202:5672
	sed -i '$a\rabbit_hosts=RabbitmqServer:5672'    /etc/cinder/cinder.conf
	sed -i "s/RabbitmqServer/${RabbitmqServer}/"    /etc/cinder/cinder.conf
	#rabbit_userid = guest
	sed -i '$a\rabbit_userid = guest'               /etc/cinder/cinder.conf
	
	service cinder-volume stop
	# mount volume
	service iscsitarget stop
	service tgt stop
	# acquire a disk	
	ls /dev/sd* | awk '$1 !~/sda/' > tmp
	for nodisk in `df -lh | awk '$1 ~/sd/ {print $1;}'`;
	do
		awk '$1 !~/'${nodisk:5:3}'/' tmp > disks
		cat disks > tmp
	done

	TargetVolume=`sed -n "1p" disks`
	rm -rf disks tmp
	
	if [ -n "$TargetVolume" ]; then
		pvcreate $TargetVolume
		vgcreate cinder-volumes $TargetVolume
		mkfs.ext4 $TargetVolume
	else
		echo "Sorry, All disk is busy, please manually add disk devices!"
	fi
	#mount /dev/sdb4 /var/lib/nova/instances/
	#chmod -R 777 /var/lib/nova/instances
	#route add -net 224.0.0.0 netmask 224.0.0.0 br0

	service iscsitarget start
	service tgt start
}

function install_network_server()
{
    apt-get install -y --force-yes quantum-server
}

function configure_network_server()
{
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/quantum.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"  /etc/quantum/quantum.conf
    ln -s /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini /etc/quantum/plugin.ini
    sed -i "s/DBServer/${DBServer}/"  /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"  /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/quantum.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"  /etc/quantum/metadata_agent.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/quantum.conf
    service quantum-server restart
}


function install_horizon()
{
    apt-get install -y --force-yes openstack-dashboard memcached python-memcache
}

function install_network_front()
{
    apt-get install -y --force-yes quantum-plugin-openvswitch-agent  quantum-dhcp-agent quantum-l3-agent
}

function configure_network_front()
{
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"  /etc/quantum/quantum.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/quantum.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"            /etc/quantum/quantum.conf

    sed -i "s/DBServer/${DBServer}/" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini

    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/metadata_agent.ini
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"  /etc/quantum/metadata_agent.ini
    sed -i "s/NovametaServer/${NovametaServer}/"  /etc/quantum/metadata_agent.ini

    service openvswitch-switch restart
    ovs-vsctl add-br br-ex
    ovs-vsctl add-br br-int
    ovs-vsctl add-br br-eth1
    ovs-vsctl add-port br-eth1 $NovaCtrlNetInterface
    service quantum-plugin-openvswitch-agent stop
    service quantum-dhcp-agent stop
    service quantum-metadata-agent stop
    service quantum-l3-agent stop
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/quantum-plugin-openvswitch-agent
    touch /etc/scaleone/guard_list/quantum-dhcp-agent
    touch /etc/scaleone/guard_list/quantum-metadata-agent
    touch /etc/scaleone/guard_list/quantum-l3-agent  
    touch /etc/scaleone/guard_list/quantum-server  
}

function install_compute_backend(){
    apt-get install --force-yes -y nova-compute-kvm
    apt-get install --force-yes -y nova-common
}

function install_prepare(){
        mkdir -p /media/apt
        mount -o loop /root/openstack.iso  /media/apt
        mv /etc/apt/sources.list  /etc/apt/sources.list.bak
        echo "deb file:///media/apt precise main" >> /etc/apt/sources.list
        apt-get update
        apt-get install -f
        apt-get install --force-yes -y cifs-utils
        apt-get install --force-yes -y sysstat
        apt-get install --force-yes -y ethtool   
}
function install_sys_patch(){
    install_prepare
    apt-get install linux-image-generic-lts-quantal -y --force-yes
    apt-get remove linux-image-3.5.0-23-generic -y --force-yes
    apt-get remove linux-headers-3.5.0-31 -y --force-yes
    apt-get remove linux-headers-3.5.0-31-generic -y --force-yes
    apt-get upgrade -y --force-yes
    apt-get install --force-yes -y qemu-kvm
    apt-get install --force-yes -y libvirt-bin
}

function configure_compute_backend()
{
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/nova/nova.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/nova/nova.conf
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"   /etc/nova/nova.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"   /etc/nova/api-paste.ini
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/nova/api-paste.ini
    sed -i "s/GlanceServer/${GlanceServer}/"         /etc/nova/nova.conf
    sed -i "s/QuantumServer/${QuantumServer}/"  /etc/nova/nova.conf
    sed -i "s/DBServer/${DBServer}/"  /etc/nova/nova.conf
    sed -i "s/QuantumMetadataServer/${QuantumMetadataServer}/"  /etc/nova/nova.conf
    sed -i "s%^libvirt_cpu_model=.*$%libvirt_cpu_model=$LibVirtCpuModel%g" /etc/nova/nova.conf
    sed -i 's/exit 0//' /etc/rc.local
    echo "ethtool -s ${NovaComputManagerInterface} wol g" >> /etc/rc.local 
    service nova-compute restart
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/nova-compute
}

function install_network_backend()
{
    apt-get install -y --force-yes openvswitch-switch
    apt-get install -y --force-yes quantum-plugin-openvswitch-agent
}


function configure_network_backend()
{
    sed -i "s/RabbitmqServer/${RabbitmqServer}/"  /etc/quantum/quantum.conf
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/"            /etc/quantum/quantum.conf
    sed -i "s/KeystoneServer/${KeystoneServer}/"  /etc/quantum/quantum.conf
    sed -i "s/DBServer/${DBServer}/" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    sed -i "s/MyPassword/${ADMIN_PASSWORD}/" /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
    ovs-vsctl add-br br-int
    ovs-vsctl add-br br-eth1
    ovs-vsctl add-port br-eth1 ${NovaComputNetInterface}
    service openvswitch-switch restart
    service quantum-plugin-openvswitch-agent restart
    mkdir -p /etc/scaleone/guard_list
    touch /etc/scaleone/guard_list/quantum-plugin-openvswitch-agent
}



function get_field() {
    while read data; do
        if [ "$1" -lt 0 ]; then
            field="(\$(NF$1))"
        else
            field="\$$(($1 + 1))"
        fi
        echo "$data" | awk -F'[ \t]*\\|[ \t]*' "{print $field}"
    done
}

function import_keystone_data()
{

    ADMIN_TENANT=$(keystone tenant-create --name=admin | grep " id " | get_field 2)
    ADMIN_USER=$(keystone user-create --name=admin --pass="$ADMIN_PASSWORD" --email=admin@domain.com | grep " id " | get_field 2)
    ADMIN_ROLE=$(keystone role-create --name=admin | grep " id " | get_field 2)

    keystone user-role-add --user-id $ADMIN_USER --role-id $ADMIN_ROLE --tenant-id $ADMIN_TENANT

   # Create services
    COMPUTE_SERVICE=$(keystone service-create --name nova --type compute --description 'OpenStack Compute Service' | grep " id " | get_field 2)
    VOLUME_SERVICE=$(keystone service-create --name cinder --type volume --description 'OpenStack Volume Service' | grep " id " | get_field 2)
    IMAGE_SERVICE=$(keystone service-create --name glance --type image --description 'OpenStack Image Service' | grep " id " | get_field 2)
    IDENTITY_SERVICE=$(keystone service-create --name keystone --type identity --description 'OpenStack Identity' | grep " id " | get_field 2)
    NETWORK_SERVICE=$(keystone service-create --name quantum --type network --description 'OpenStack Networking service' | grep " id " | get_field 2)

# Create endpoints
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $COMPUTE_SERVICE --publicurl 'http://'"$KEYSTONE_HOST"':8774/v2/$(tenant_id)s' --adminurl 'http://'"$KEYSTONE_HOST"':8774/v2/$(tenant_id)s' --internalurl 'http://'"$KEYSTONE_HOST"':8774/v2/$(tenant_id)s'
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $VOLUME_SERVICE --publicurl 'http://'"$KEYSTONE_HOST"':8776/v1/$(tenant_id)s' --adminurl 'http://'"$KEYSTONE_HOST"':8776/v1/$(tenant_id)s' --internalurl 'http://'"$KEYSTONE_HOST"':8776/v1/$(tenant_id)s'
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $IMAGE_SERVICE --publicurl 'http://'"$KEYSTONE_HOST"':9292/v2' --adminurl 'http://'"$KEYSTONE_HOST"':9292/v2' --internalurl 'http://'"$KEYSTONE_HOST"':9292/v2'
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $IDENTITY_SERVICE --publicurl 'http://'"$KEYSTONE_HOST"':5000/v2.0' --adminurl 'http://'"$KEYSTONE_HOST"':35357/v2.0' --internalurl 'http:// '"$KEYSTONE_HOST"':5000/v2.0'
    keystone endpoint-create --region $KEYSTONE_REGION --service-id $NETWORK_SERVICE --publicurl 'http://'"$KEYSTONE_HOST"':9696/' --adminurl 'http://'"$KEYSTONE_HOST"':9696/' --internalurl 'http:// '"$KEYSTONE_HOST"':9696/'
}

function sync_sshkey()
{
    echo "sync ssh key please"
}

function make_logrotate_conf()
{
    back_size=$1
    count=$2
    if [[ ${back_size} == "" ]];then
        echo "doest not input back log size, unit M"
        exit
    fi
    
    if [[ ${count} == "" ]];then
        echo "doest not input back log record count"
        exit
    fi
    
    echo "
    /var/log/cinder/*.log
    {
           copytruncate
           size ${back_size}M
           rotate $count
    }
    /var/log/nova/*.log
    {
           copytruncate
           size ${back_size}M
           rotate $count
    }    
    /var/log/keystone/*.log
    {
           copytruncate
           size ${back_size}M
           rotate $count
    }    
    /var/log/glance/*.log
    {
           copytruncate
           size ${back_size}M
           rotate $count
    }    
 
    /var/log/quantum/*.log
    {
           copytruncate
           size ${back_size}M
           rotate $count
    }" > /etc/logrotate_openstack.conf
}

function add_logrotate_to_task()
{
    back_time=$1
    exist_task=`cat /etc/crontab | grep logrotate_openstack -c`
    if [[ $exist_task != 0 ]];then
        return 0
    fi
    
    echo "0 $back_time * * * root logrotate /etc/logrotate_openstack.conf 2>/dev/null" >> /etc/crontab
}

function make_openstack_version()
{
	mkdir -p /etc/scaleone/
	echo "scaleone version: $OPENSTACK_VER" > /etc/scaleone/version.txt
}

function scaleone_rollback()
{
  #mkdir -p /media/apt
  #mount -o loop /root/openstack.iso  /media/apt
  #mv /etc/apt/sources.list  /etc/apt/sources.list.bak
  #echo "deb file:///media/apt precise main" >> /etc/apt/sources.list
  #apt-get update
  #apt-get install -f
  umount /media/apt
     
	ovs-vsctl del-br br-int
	ovs-vsctl del-br br-eth1
  
  /etc/init.d/keepalived stop
  apt-get purge -y --force-yes keepalived
  rm -fR /etc/scaleone/ha/
  
	echo "#####start remove quantum and openwswitch#####"
	apt-get purge  -y --force-yes quantum-plugin-openvswitch-agent
	apt-get purge  -y --force-yes openvswitch-switch
	#apt-get autoremove -y --force-yes
	echo "#####stop remove quantum and openwswitch#####"
	
	echo "#####start remove cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient#####"
	apt-get purge -y --force-yes cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient linux-headers-`uname -r`
	echo "#####stop remove cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient #####"
	
	echo "#####start remove nova-compute-kvm#####"
	apt-get purge --force-yes -y nova-compute-kvm
	#apt-get autoremove -y --force-yes
	echo "#####stop remove nova-compute-kvm #####"
	
	echo "#####start remove qemu-kvm libvirt-bin#####"
  apt-get purge --force-yes -y qemu-kvm
  apt-get purge --force-yes -y libvirt-bin
  echo "#####stop remove qemu-kvm libvirt-bin#####"
  
  #apt-get autoremove -y --force-yes
  
  ## 删除多余的qutuan包和nova 包
  quantum_list=`dpkg -l | grep quantum | awk -F ' ' '{print $2}'`
  echo "#######will remove $quantum_list#######"
  for i in $quantum_list
  do 
  	echo "#####remove $i#####"
  	apt-get purge --force-yes -y $i
  done
  
  nova_list=`dpkg -l | grep nova | awk -F ' ' '{print $2}'`
  echo "#######will remove $nova_list#######"
  for i in $nova_list
  do 
  	echo "#####remove $i#####"
  	apt-get purge --force-yes -y $i
  done
 
  cinder_list=`dpkg -l | grep cinder | awk -F ' ' '{print $2}'`
  echo "#######will remove $cinder_list#######"
  for i in $cinder_list
  do 
  	echo "#####remove $i#####"
  	apt-get purge --force-yes -y $i
  done

  glance_list=`dpkg -l | grep glance | awk -F ' ' '{print $2}'`
  echo "#######will remove $glance_list#######"
  for i in $glance_list
  do 
  	echo "#####remove $i#####"
  	apt-get purge --force-yes -y $i
  done
  
  keystone_list=`dpkg -l | grep keystone | awk -F ' ' '{print $2}'`
  echo "#######will remove $keystone_list#######"
  for i in $keystone_list
  do 
  	echo "#####remove $i#####"
  	apt-get purge --force-yes -y $i
  done
  
  apt-get purge kvm-ipxe --force-yes -y
  apt-get purge qemu-system-common --force-yes -y
  apt-get purge qemu-keymaps --force-yes -y
  apt-get purge qemu-utils --force-yes -y
  rm -f /dev/kvm 
  rm -fR  /var/lib/nova/instances/*
  rm -f   /var/lock/nova/*

  
  #apt-get install -y --force-yes bridge-utils
	
	echo "##############################" > /etc/rc.local
  #rm -fR /var/lib/nova/
  #rm -fR /var/lib/libvirt/
  #rm -fR /var/log/nova/
  #rm -fR /var/log/libvirt
   rm ~/.ssh/known_hosts
   
  dns_masq=`ps -Alf | grep dnsmasq |grep -v grep| awk -F ' ' '{print $4}'`
  kill -9 $dns_masq
  
  apt-get purge dnsmasq-base --force-yes -y
  
  /etc/init.d/mysql stop
  apt-get purge -y --force-yes ntp
  apt-get purge -y --force-yes python-mysqldb
  apt-get -y --force-yes autoremove mysql* --purge
  apt-get -y --force-yes remove apparmor --purge
  rm -fR /etc/mysql/
  rm -fR /var/lib/mysql/
  rm -fR /var/log/mysql
  
  userdel nova
  userdel libvirt-qemu
  userdel libvirt-dnsmasq
  userdel  cinder
  userdel  quantum
  groupdel kvm
  groupdel libvirtd
}

function exce_log_manager_task()
{
    # make cron config
    make_logrotate_conf $LOG_BACK_MAX_SIZE $LOG_BACK_NUM
    # make cron 
    add_logrotate_to_task $LOG_BACK_TIME
    # add cron to autorun 
    echo "crontab /etc/crontab" >> /etc/init.d/rc.local
    # start run task
    crontab /etc/crontab
}

case "$1" in
    "control")
        make_openstack_version
        install_prepare
        install_deps
        install_db_client
        install_mq

        install_glance
        configure_glance

        install_keystone
        configure_keystone
    
   
        install_cinder_server
        configure_cinder_server
    
        install_compute_server
        configure_compute_server

#       install_horizon

        install_network_server
        configure_network_server
    
       import_keystone_data
       exce_log_manager_task
    ;;
    "network")      
        install_deps
        install_network_front
        configure_network_front
        exce_log_manager_task
    ;;
    "compute")
        make_openstack_version
        install_prepare
        install_deps
        install_compute_backend
        configure_compute_backend
    
        install_cinder_backend
        configure_cinder_backend

        install_network_backend
        configure_network_backend
        exce_log_manager_task
        ;;
     "db")
        make_openstack_version
        install_prepare
        install_deps
        install_db
        configure_db
        ;;
      "sys_patch")
        install_sys_patch
        ;;
      "roll_back")
      	scaleone_rollback
      	;;
      "")
          echo "sys_patch  install system base package"
          echo "db  install ScaleOne db node"
          echo "compute  install ScaleOne compute node"
          echo "control  install ScaleOne control node"
          echo "network  install ScaleOne network manager on control node"
          ;;
        *)
        $1
        ;;
esac

    
   
