#!/bin/bash
#clear
#read -p "Enter Number of Compute to Add " count
#echo $count
#a = 0
#while [ $a -lt $count ]
#do
#read -p "Enter Compute User Name: " username
#echo $username
#read -p "Enter Compute Hostname: " hostname
#echo $hostname
#read -p "Enter First Network Interface : " interface
#echo $interface
#read -p "Enter Second Network Interface: " interface2
#echo $interface2
#read -p "Enter Compute IP address: " ip
#echo $ip

username="compute_username"
hostname="compute_hostname"
interface="compute_network_interface_1"
interface2="compute_network_interface_2"
ip="compute_ip_addr"


sudo -s scp /etc/hosts $username@$hostname:/home/$username
ssh $username@$hostname 'sudo -S adduser --disabled-password --gecos "" nova'
ssh $username@$hostname 'sudo -S adduser --disabled-password --gecos "" neutron'
ssh $username@$hostname 'sudo -S adduser --disabled-password --gecos "" cinder'

#-------------------------NOVA----------------------------------------------
sudo -s scp /etc/nova/nova.conf $username@$hostname:/home/$username
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/nova.conf /etc/nova/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R nova:nova /etc/nova/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R nova:nova /var/lib/nova/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/my_ip = .*/my_ip = '$ip'/g" /etc/nova/nova.conf'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/#novncproxy_host = .*/novncproxy_host = /g" /etc/nova/nova.conf'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/novncproxy_host = .*/novncproxy_host = http:\/\/'$hostname'/g" /etc/nova/nova.conf'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/server_listen = .*/server_listen = 0.0.0.0/g" /etc/nova/nova.conf'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/server_proxyclient_address = .*/server_proxyclient_address = '$hostname'/g" /etc/nova/nova.conf'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R nova:nova /var/log/nova/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl enable nova-compute.service'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl start nova-compute.service'
sleep 5
openstack compute service list

#-------------------------Neutron----------------------------------------------

sudo -s  scp /etc/neutron/neutron.conf $username@$hostname:/home/$username
sudo -s  scp -r /etc/neutron/plugins/ml2/* $username@$hostname:/home/$username
sudo -s  scp /etc/neutron/dhcp-agent.ini $username@$hostname:/home/$username

ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/neutron.conf /etc/neutron/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/ml2_conf.ini /etc/neutron/plugins/ml2/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/dhcp-agent.ini /etc/neutron/'

ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R neutron:neutron /var/lib/neutron/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R neutron:neutron /etc/neutron/'
	
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S echo "neutron ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/neutron'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S update-alternatives --set ebtables /usr/sbin/ebtables-legacy'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/physical_interface_mappings = .*/physical_interface_mappings = provider:$interface2/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/local_ip = .*/local_ip = '$ip'/g" /etc/neutron/plugins/ml2/linuxbridge_agent.ini'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S chown -R neutron:neutron /var/log/neutron/'

ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl enable neutron-dhcp-agent.service'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl start neutron-dhcp-agent.service'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl start neutron-metadata-agent.service'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S systemctl start neutron-linuxbridge-agent.service'
sleep 5
openstack network agent list
#-------------------------Cinder----------------------------------------------
sudo -s  scp /etc/cinder/cinder.conf $username@$hostname:/home/$username
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S mv /home/'$username'/cinder.conf /etc/cinder/'
ssh -o StrictHostKeyChecking=no  -t $username@$hostname 'sudo -S sed -i "s/my_ip = .*/my_ip = '$ip'/g" /etc/cinder/cinder.conf'
ssh -o StrictHostKeyChecking=no  $username@$hostname 'sudo -S chown -R cinder:cinder /etc/cinder/'
	
ssh -o StrictHostKeyChecking=no $username@$hostname 'sudo -S chown -R cinder:cinder /var/log/cinder/'
sleep 5
openstack volume service list
#echo $a
a=`expr $a + 1`
done
