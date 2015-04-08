#! /bin/bash
# This is basic script I am using and appending to make my https://vagrantcloud.com/junaid18183/boxes/centos_65 usable.
 
# Add the belw section in the Vagrant File
 
# Vagrant.configure("2") do |config|
#  config.vm.provision "shell", path: "https://gist.githubusercontent.com/junaid18183/62b8a4b006c68846f385/raw/7bacafd3998d33aecfe76f8b80666e611657ddb5/boot.sh"
#end
 

# set resolv.conf #Removed will take this part in puppet
# set the /etc/hosts file #Removed will take this part in puppet

#Install packages 

echo "Install Required Packages"

yum install -y vim-enhanced git python-setuptools.noarch  nc bc  httpd.x86_64 tree MySQL-python.x86_64 man man-pages mlocate libselinux-python> /tmp/vagrant_boot.log 2>&1
easy_install pip > /tmp/vagrant_boot.log 2>&1

# prettytable required for Sojourner
pip install prettytable > /tmp/vagrant_boot.log 2>&1
pip install argparse > /tmp/vagrant_boot.log 2>&1

#Turn Off Selinux"
echo "Disable Selinux"
setenforce  0 ; echo 0 > /selinux/enforce
sed -i '/^SELINUX=/d' /etc/selinux/config ; echo 'SELINUX=disabled' >> /etc/selinux/config

#Add datar.pub in authorized_keys
echo "Add Datar.public key in /root/.ssh/authorized_keys"
touch /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA0VbBODTG723YPz/ikwDIbZ55lMTH4HuGbSgnRsKcaFEioNueemJM2HYidAukoBPnxL9Q/0n6FWsmOdxsZfeU7GvmjTDwsF9NBC2r3rNtQOKyjdResLlY3ZAe/9SSCzejAEFCDVBBoWDYDLpllQ3b4QCwKyt9bV07pNJdCsk6w5U= datar_key" > /root/.ssh/authorized_keys

#Remove the previous id_rsa and id_rsa.pub files and change them with datar.key
# \cp makes to bypass the alias of cp
\cp /plugins_scripts/Keys/datar-for-machines/datar.id_rsa.pub /root/.ssh/id_rsa.pub
\cp /plugins_scripts/Keys/datar-for-machines/datar.id_rsa /root/.ssh/id_rsa

#Disbale IPV6
echo "Disable ipv6"
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
#or 
#echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
#echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6

echo -e "NETWORKING_IPV6=no\nIPV6INIT=no" >> /etc/sysconfig/network