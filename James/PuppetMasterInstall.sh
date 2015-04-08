rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
yum install -y puppet-server puppetdb
rsync -av /vagrant/manifests/master_puppet.conf /etc/puppet/puppet.conf
rsync -av /vagrant/manifests/ps1.sh  /etc/profile.d/
# start puppet, let it create the cert it needs then stop it
puppet master --verbose --no-daemonize & k=$! && sleep 7 && kill $k