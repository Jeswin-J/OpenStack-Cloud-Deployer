#read -p "Enter Network Interface: " interface
#echo $interface
#read -p "Enter Second Network Interface: " interface2
#echo $interface2
#read -p "Enter ip address: " ip
#echo $ip
#read -p "Enter the Storage device for Cinder Volume [sdb1,vdb1]:" device
#echo $device

interface="first_interface"
interface2="second_interface"
ip="internet_protocol"
device="cinder_storage_device_name"


hostname=`cat /etc/hostname`
echo $hostname
export user=`whoami`
sudo echo "$ip $hostname" | sudo tee -a /etc/hosts
sudo sed -i "s/127.0.1.1.*/$ip $hostname/g" /etc/hosts
sudo cat /etc/hosts

sudo sed -i "s/bind-address = .*/bind-address = $ip/g" /etc/mysql/mariadb.conf.d/50-server.cnf  
sudo rm -rf /var/lib/mysql/ib_logfile*
sudo -s service mysql restart
sudo -s mysql -uroot -pCloud@123 < /opt/openstack.sql
sleep 5

#interface=`sudo ip -o link show | sed -rn '/^[0-9]+: en/{s/.: ([^:]*):.*/\1/p}'`
#ip=`sudo ifconfig $interface | grep inet |awk {'print $2'} | cut -d ":" -f2 |head -n1`

sudo adduser --system --shell=/bin/false --disabled-password --gecos "" keystone
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" glance
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" nova
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" neutron
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" cinder
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" horizon
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" placement
sudo adduser --system --shell=/bin/false --disabled-password --gecos "" swift

sudo cp -r /opt/startup/* /home/$user/
sudo chown -R $user:$user /home/$user/
sudo usermod -G kvm $user
sudo usermod -G libvirt $user

sudo sed -i "s/OS_AUTH_URL=.*/OS_AUTH_URL=http:\/\/$hostname:5000\/v3/g"  /home/$user/openrc
sudo sed -i "s/-l .*/-l $hostname/g"  /etc/memcached.conf
sudo sed -i "s/NODE_IP_ADDRESS=.*/NODE_IP_ADDRESS=$ip/g" /etc/rabbitmq/rabbitmq-env.conf
sudo chown -R rabbitmq:rabbitmq /var/log/rabbitmq/

sudo /etc/init.d/rabbitmq-server stop
sleep 2
sudo pkill epmd
sleep 2
sudo pkill erl
sleep 2
sudo rm -rf /var/lib/rabbitmq/mnesia/*
sudo chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
sleep 2
sudo service rabbitmq-server start

#file="/etc/rabbitmq/rabbitmq.config"
#if [ ! -f "$file" ]
#then
# echo "File '$
#{file}' not found."
# cat >> /etc/rabbitmq/rabbitmq.config << EOF
#[{rabbit, [{loopback_users, []}]}].
#EOF
#pkill -f rabbitmq
#service rabbitmq-server sto
#service rabbitmq-server start
#rabbitmqctl add_user openstack rabbit
#rabbitmqctl set_permissions openstack ".*" ".*" ".*"
#service rabbitmq-server restart
#else
# echo "File '${file}' exists."
#sudo service rabbitmq-server stop
#sudo service rabbitmq-server restart
sleep 5
sudo rabbitmqctl add_user openstack rabbit
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"
sudo service rabbitmq-server restart
sleep 5

sudo /etc/init.d/apache2 restart
sudo sed -i "s/ETCD_NAME=.*/ETCD_NAME=\"$hostname\"/g"  /etc/default/etcd
sudo sed -i "s/ETCD_INITIAL_CLUSTER=.*/ETCD_INITIAL_CLUSTER=\"$hostname=http:\/\/$ip:2380\"/g"  /etc/default/etcd
sudo sed -i "s/ETCD_INITIAL_ADVERTISE_PEER_URLS=.*/ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http:\/\/$ip:2380\"/g" /etc/default/etcd
sudo sed -i "s/ETCD_ADVERTISE_CLIENT_URLS=.*/ETCD_ADVERTISE_CLIENT_URLS=\"http:\/\/$ip:2379\"/g" /etc/default/etcd
sudo sed -i "s/ETCD_LISTEN_CLIENT_URLS=.*/ETCD_LISTEN_CLIENT_URLS=\"http:\/\/$ip:2379\"/g" /etc/default/etcd
sudo /etc/init.d/etcd restart

#**********************************Keystone*****************************************************************************
sudo sed -i "s/connection = .*/connection = mysql+pymysql:\/\/keystone:keystone@$hostname\/keystone/g" /etc/keystone/keystone.conf
sudo sed -i "s/memcache_servers = .*/memcache_servers = $hostname:11211/g"  /etc/keystone/keystone.conf
#***********************************Glance********************************************************************************
sudo sed -i "s/connection = .*/connection = mysql+pymysql:\/\/glance:glance@$hostname\/glance/g" /etc/glance/glance-api.conf
sudo sed -i "s/default_store =.*/default_store = file /g" /etc/glance/glance-api.conf
sudo sed -i "s/www_authenticate_uri = .*/www_authenticate_uri = http:\/\/$hostname:5000/g" /etc/glance/glance-api.conf
sudo sed -i "s/auth_uri = .*/auth_uri = http:\/\/$hostname:5000/g" /etc/glance/glance-api.conf
sudo sed -i "s/auth_url = .*/auth_url = http:\/\/$hostname:5000/g" /etc/glance/glance-api.conf
sudo sed -i "s/memcached_servers = .*/memcached_servers = $hostname:11211/g" /etc/glance/glance-api.conf

#****************************************Nova****************************************************************************
sudo sed -i "s/my_ip = .*/my_ip = $ip/g" /etc/nova/nova.conf
sudo sed -i '/^\[api_database\]$/ , /^\[.*\]$/   s/connection = .*/connection = mysql+pymysql:\/\/nova:nova@'$hostname'\/nova_api /g' /etc/nova/nova.conf
sudo sed -i '/^\[database\]$/ , /^\[.*\]$/   s/connection = .*/connection = mysql+pymysql:\/\/nova:nova@'$hostname'\/nova /g' /etc/nova/nova.conf
sudo sed -i '/^\[neutron\]$/ , /^\[.*\]$/   s/url = .*/url = http:\/\/'$hostname':9696 /g' /etc/nova/nova.conf
sudo sed -i '/^\[neutron\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000\/v3 /g' /etc/nova/nova.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000\/v3 /g' /etc/nova/nova.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/www_authenticate_uri = .*/www_authenticate_uri = http:\/\/'$hostname':5000\/v3 /g' /etc/nova/nova.conf
sudo sed -i '/^\[placement\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000\/v3 /g' /etc/nova/nova.conf
sudo sed -i '/^\[DEFAULT\]$/ , /^\[.*\]$/   s/transport_url = .*/transport_url = rabbit:\/\/openstack:rabbit@'$hostname' /g' /etc/nova/nova.conf
sudo sed -i '/^\[oslo_messaging_notifications\]$/ , /^\[.*\]$/   s/transport_url = .*/transport_url = rabbit:\/\/openstack:rabbit@'$hostname' /g' /etc/nova/nova.conf
sudo sed -i "s/memcache_servers = .*/memcache_servers = $hostname:11211/g" /etc/nova/nova.conf
sudo sed -i "s/api_servers = .*/api_servers = http:\/\/$hostname:9292/g" /etc/nova/nova.conf
#sudo sed -i "s/novncproxy_host = .*/novncproxy_host = http:\/\/$hostname/g" /etc/nova/nova.conf
sudo sed -i "s/memcached_servers = .*/memcached_servers = $hostname:11211/g" /etc/nova/nova.conf
sudo sed -i "s/server_listen = .*/server_listen = 0.0.0.0/g" /etc/nova/nova.conf
sudo sed -i "s/server_proxyclient_address = .*/server_proxyclient_address = $hostname/g" /etc/nova/nova.conf
sudo sed -i "s/novncproxy_base_url = .*/novncproxy_base_url = http:\/\/$ip:6080\/vnc_auto.html/g" /etc/nova/nova.conf
#sudo sed -i "s/novncproxy_host = .*/novncproxy_host = '$hostname'/g" /etc/nova/nova.conf
#*************************************Placement* ************************************************************************

sudo sed -i '/^\[placement_database\]$/ , /^\[.*\]$/   s/connection = .*/connection = mysql+pymysql:\/\/placement:placement@'$hostname'\/placement /g' /etc/placement/placement.conf
sudo sed -i "s/auth_url = .*/auth_url = http:\/\/$hostname:5000\/v3 /g" /etc/placement/placement.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/www_authenticate_uri = .*/www_authenticate_uri = http:\/\/'$hostname':5000\/v3 /g' /etc/placement/placement.conf
sudo sed -i "s/memcached_servers = .*/memcached_servers = $hostname:11211/g" /etc/placement/placement.conf

#*********************************Neutron****************************************************************************************
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000\/v3 /g' /etc/neutron/neutron.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/www_authenticate_uri = .*/www_authenticate_uri = http:\/\/'$hostname':5000\/v3 /g' /etc/neutron/neutron.conf
sudo sed -i '/^\[nova\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000\/v3 /g' /etc/neutron/neutron.conf
sudo sed -i '/^\[DEFAULT\]$/ , /^\[.*\]$/   s/transport_url = .*/transport_url = rabbit:\/\/openstack:rabbit@'$hostname' /g' /etc/neutron/neutron.conf
sudo sed -i "s/connection = .*/connection = mysql+pymysql:\/\/neutron:neutron@$hostname\/neutron/g" /etc/neutron/neutron.conf
sudo sed -i "s/auth_uri = .*/auth_uri = http:\/\/$hostname:5000/g" /etc/neutron/neutron.conf
sudo sed -i "s/memcached_servers = .*/memcached_servers = $hostname:11211/g" /etc/neutron/neutron.conf
sudo sed -i "s/physical_interface_mappings = .*/physical_interface_mappings = provider:$interface2/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
#sudo sed -i "s/bridge_mappings = .*/bridge_mappings = provider:$br-provider/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
sudo sed -i "s/local_ip = .*/local_ip = $ip/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini
sudo sed -i "s/local_ip = .*/local_ip = $ip/g" /etc/neutron/plugins/ml2/openvswitch_agent.ini
sudo sed -i "s/nova_metadata_host = .*/nova_metadata_host = $hostname/g" /etc/neutron/metadata_agent.ini

#*********************************Cinder*****************************************************************************************
sudo sed -i "s/my_ip = .*/my_ip = $ip/g" /etc/cinder/cinder.conf
sudo sed -i "s/glance_api_servers = .*/glance_api_servers = $hostname:9292/g" /etc/cinder/cinder.conf
sudo sed -i '/^\[DEFAULT\]$/ , /^\[.*\]$/   s/transport_url = .*/transport_url = rabbit:\/\/openstack:rabbit@'$hostname' /g' /etc/cinder/cinder.conf
sudo sed -i '/^\[oslo_messaging_notifications\]$/ , /^\[.*\]$/   s/transport_url = .*/transport_url = rabbit:\/\/openstack:rabbit@'$hostname' /g' /etc/cinder/cinder.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/auth_url = .*/auth_url = http:\/\/'$hostname':5000/g' /etc/cinder/cinder.conf
sudo sed -i '/^\[keystone_authtoken\]$/ , /^\[.*\]$/   s/www_authenticate_uri = .*/www_authenticate_uri = http:\/\/'$hostname':5000/g' /etc/cinder/cinder.conf
sudo sed -i "s/connection = .*/connection = mysql+pymysql:\/\/cinder:cinder@$hostname\/cinder/g" /etc/cinder/cinder.conf
#sed -i "s/auth_uri = .*/auth_uri = http:\/\/$hostname:5000/g" /etc/cinder/cinder.conf
sudo sed -i "s/memcached_servers = .*/memcached_servers = $hostname:11211/g" /etc/cinder/cinder.conf

#**********************************Horizon*****************************************************************************************
sudo sed -i "s/OPENSTACK_HOST = .*/OPENSTACK_HOST = \"$hostname\"/g" /etc/openstack_dashboard/local_settings.py
sudo sed -i "s/OPENSTACK_KEYSTONE_URL = .*/OPENSTACK_KEYSTONE_URL = \"http:\/\/$hostname:5000\/v3\"/g" /etc/openstack_dashboard/local_settings.py
sudo sed -i "s/'LOCATION': .*/'LOCATION': \'$hostname:11211\'/g" /etc/openstack_dashboard/local_settings.py
sudo sed -i "s/ServerName .*/ServerName $hostname/g" /etc/apache2/apache2.conf 
sudo sed -i "s/ServerName .*/ServerName $hostname/g" /etc/apache2/sites-available/horizon.conf


sudo chown -R keystone:keystone /etc/keystone/
sudo keystone-manage db_sync
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sudo keystone-manage bootstrap --bootstrap-password Cloud@123 --bootstrap-admin-url http://$hostname:5000/v3/ --bootstrap-internal-url http://$hostname:5000/v3/ --bootstrap-public-url http://$hostname:5000/v3/ --bootstrap-region-id RegionOne
sudo /etc/init.d/apache2 restart

. /home/$user/openrc
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password demo demo
openstack role create user
openstack role add --project demo --user demo user
openstack token issue
sleep 3

openstack user create --domain default --password glance glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://$hostname:9292
openstack endpoint create --region RegionOne image internal http://$hostname:9292
openstack endpoint create --region RegionOne image admin http://$hostname:9292
sudo glance-manage db_sync
sudo systemctl enable glance.service
sudo chown -R glance:glance /var/log/glance/
sudo chown -R glance:glance /var/lib/glance/
sudo chown -R glance:glance /etc/glance/
sleep 2
sudo systemctl start glance.service
sleep 2
#sudo systemctl status glance.service
#sh /home/$user/glance.sh
#sh /home/$user/scripts/glance.sh
sleep 10
openstack image create "cirros" --file /home/$user/cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public
sleep 10
openstack image list

openstack user create --domain default --password nova nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://$hostname:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://$hostname:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://$hostname:8774/v2.1
sudo nova-manage api_db sync
#sudo service libvirtd stop
#sudo service libvirtd start
#sh /home/$user/nova-compute.sh
sudo chown -R nova:nova /var/log/nova/
sudo chown -R nova:nova /var/lib/nova/
sudo chown -R nova:nova /etc/nova/
#sudo systemctl enable nova-compute.service
sleep 5
#sudo systemctl start nova-compute.service
#sleep 2
#sudo systemctl status nova-compute.service
#sleep 2
sudo nova-manage cell_v2 map_cell0
sudo nova-manage cell_v2 create_cell --name=cell1 --verbose
sudo nova-manage db sync
sudo nova-manage cell_v2 list_cells
sudo nova-manage cell_v2 discover_hosts --verbose
#sudo openstack catalog list
#sudo nova-status upgrade check
#sh /home/$user/nova.sh
sudo systemctl enable nova-api.service
sudo systemctl start  nova-api.service
sudo systemctl enable nova-scheduler.service
sudo systemctl start  nova-scheduler.service
sudo systemctl enable nova-conductor.service
sudo systemctl start  nova-conductor.service
sudo systemctl enable nova-novncproxy.service
sudo systemctl start  nova-novncproxy.service

#sudo sytemctl status nova.service
sleep 5
#sh /home/$user/nova-compute.sh
sudo systemctl enable nova-compute.service
sudo systemctl start nova-compute.service
#sudo systemctl status nova-compute.service
sleep 5
#sh nova-stop.sh
#sleep 5
#sh nova-start.sh
openstack compute service list


openstack user create --domain default --password placement placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://$hostname:8778
openstack endpoint create --region RegionOne placement internal http://$hostname:8778
openstack endpoint create --region RegionOne placement admin http://$hostname:8778
sudo placement-manage db sync  
sudo service apache2 restart
sudo placement-status upgrade check
sudo openstack catalog list
sudo nova-status upgrade check

openstack user create --domain default --password neutron neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "Openstack Networking" network
openstack endpoint create --region RegionOne network public http://$hostname:9696
openstack endpoint create --region RegionOne network internal http://$hostname:9696
openstack endpoint create --region RegionOne network admin http://$hostname:9696
neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head
#sh /home/$user/neutron.sh
sudo chown -R neutron:neutron /var/log/neutron/
sudo chown -R neutron:neutron /var/lib/neutron/
sudo chown -R neutron:neutron /etc/neutron/
sudo systemctl enable neutron.service
sudo systemctl start  neutron.service
sudo systemctl enable neutron-dhcp-agent.service
sudo systemctl start  neutron-dhcp-agent.service
sudo systemctl enable neutron-metadata-agent.service
sudo systemctl start  neutron-metadata-agent.service
sudo systemctl enable neutron-l3-agent.service
sudo systemctl start  neutron-l3-agent.service
#sudo systemctl enable neutron-openvswitch-agent.service
#sudo systemctl enable neutron-openvswitch-agent.service
sudo systemctl enable neutron-linuxbridge-agent.service
sudo systemctl start neutron-linuxbridge-agent.service
sleep 5
openstack network agent list

openstack user create --domain default --password cinder cinder
openstack role add --project service --user cinder admin
openstack role add --project service --user cinder admin
openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3
openstack endpoint create --region RegionOne volumev2 public http://$hostname:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://$hostname:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://$hostname:8776/v2/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 public http://$hostname:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://$hostname:8776/v3/%\(project_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://$hostname:8776/v3/%\(project_id\)s
sudo cinder-manage db sync
#sh /home/$user/cinder.sh 
sudo chown -R cinder:cinder /var/log/cinder/
sudo chown -R cinder:cinder /var/lib/cinder/
sudo chown -R cinder:cinder /etc/cinder/
sudo systemctl enable cinder.service
sudo systemctl start cinder.service
sudo systemctl enable cinder-scheduler.service
sudo systemctl start cinder-scheduler.service
sudo pvcreate /dev/$device
sudo vgcreate cinder-volumes /dev/$device
sudo systemctl enable cinder-volume.service
sudo systemctl start cinder-volume.service
sleep 5
openstack volume service list

sudo chmod -R 777 /usr/local/lib/python3.9/dist-packages/openstack_dashboard/openstack_dashboard/static/
sudo chmod -R 777 /usr/local/lib/python3.9/dist-packages/openstack_dashboard/openstack_dashboard/local
sudo chmod -R 600 /usr/local/lib/python3.9/dist-packages/openstack_dashboard/openstack_dashboard/local/.secret_key_store
sudo /etc/init.d/memcached restart
sudo /etc/init.d/apache2 restart

/opt/firefox/firefox http://$hostname

