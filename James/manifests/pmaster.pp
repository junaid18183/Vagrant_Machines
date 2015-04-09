package {["httpd","httpd-devel","mod_ssl","ruby-devel","rubygems","gcc","libcurl-devel","openssl-devel","zlib-devel","apr-devel","apr-util-devel"]:
  notify => Exec['install_passenger_gem'],
}


# puppetdb configuration
#                                        __       __  __
#                                       /\ \__   /\ \/\ \
#  _____   __  __  _____   _____      __\ \ ,_\  \_\ \ \ \____
# /\ '__`\/\ \/\ \/\ '__`\/\ '__`\  /'__`\ \ \/  /'_` \ \ '__`\
# \ \ \L\ \ \ \_\ \ \ \L\ \ \ \L\ \/\  __/\ \ \_/\ \L\ \ \ \L\ \
#  \ \ ,__/\ \____/\ \ ,__/\ \ ,__/\ \____\\ \__\ \___,_\ \_,__/
#   \ \ \/  \/___/  \ \ \/  \ \ \/  \/____/ \/__/\/__,_ /\/___/
#    \ \_\           \ \_\   \ \_\
#     \/_/            \/_/    \/_/
#
package {["puppetdb", "puppet", "puppetdb-terminus"]:
}

package {"postgresql-server":
  notify => Exec['configurepostgresql'],
}

service {"postgresql":
  ensure => "running",
  enable => "true",
  require => Package['postgresql-server'],
}

exec {'configurepostgresql':
  command     => "/bin/bash /vagrant/manifests/configurepsql.sh",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  refreshonly => true,
}

service {"puppetdb":
  ensure  => "running",
  enable  => "true",
  require => [Package['puppetdb'],File['/etc/puppet/puppetdb.conf'], Exec['configSSLpuppetdb'] ],
}

exec {'configSSLpuppetdb':
  command     => "/usr/sbin/puppetdb ssl-setup",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
}

file {"/etc/puppetdb/conf.d/database.ini":
  source => "/vagrant/manifests/database.ini",
  ensure => file,
  owner  => puppetdb,
  group  => puppetdb,
  mode   => 640,
  require => Package['puppetdb'],
}

file {"/etc/puppet/puppetdb.conf":
  source => "/vagrant/manifests/puppetdb.conf",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 755,
  notify => Exec['configSSLpuppetdb'],
}

file {"/etc/puppet/routes.yaml":
  source => "/vagrant/manifests/routes.yaml",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 755,
}

file {"/etc/puppetdb/conf.d/jetty.ini":
  source => "/vagrant/manifests/pmaster_jetty.ini",
  ensure => file,
  owner  => puppetdb,
  group  => puppetdb,
  mode   => 755,
}

# Install puppetdb-ruby gem

package { 'ruby-puppetdb':
    ensure   => 'installed',
    provider => 'gem',
}

##### BEGIN r10k install section ######
#
#          _     __   __
#        /' \  /'__`\/\ \
#  _ __ /\_, \/\ \/\ \ \ \/'\
# /\`'__\/_/\ \ \ \ \ \ \ , <
# \ \ \/   \ \ \ \ \_\ \ \ \\`\
#  \ \_\    \ \_\ \____/\ \_\ \_\
#   \/_/     \/_/\/___/  \/_/\/_/
#
exec {'r10kinstall':
  command     => "/usr/bin/puppet module install zack-r10k",
  creates     => "/etc/r10k.yaml",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  require     => [ Package['puppet'], File['/tmp/r10kinstall.pp']],
  notify      => Exec['installr10k'],
}

file {"/tmp/r10kinstall.pp":
  content => "class {'r10k': remote => 'git@github.com:junaid18183/Puppet_Repository.git', }",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 750,
}

exec {'configureGit':
  environment => ["HOME=/root"],
  command     => "/usr/bin/git config --global http.sslVerify false",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  refreshonly => true,
}

exec {'installr10k':
  command     => "/usr/bin/puppet apply /tmp/r10kinstall.pp",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  refreshonly => true,
  notify      => Exec['configureGit'],
}

# every 5 min checkout new source, using array instead of */5
# to ensure it works with any cron deamon
cron {"r10k":
  command => "/usr/bin/r10k deploy environment > /dev/null 2>&1",
  user    => root,
  minute  => [0,5,10,15,20,25,30,35,40,45,50,55],
}
####### END r10k install section ######


##### BEGIN hiera install section ######
#  __
# /\ \      __
# \ \ \___ /\_\     __   _ __    __
#  \ \  _ `\/\ \  /'__`\/\`'__\/'__`\
#   \ \ \ \ \ \ \/\  __/\ \ \//\ \L\.\_
#    \ \_\ \_\ \_\ \____\\ \_\\ \__/.\_\
#     \/_/\/_/\/_/\/____/ \/_/ \/__/\/_/
#
#
package {"hiera":}

# this is were hiera defaults to pointing
file {"/etc/hiera.yaml":
  target => "/etc/puppet/hiera.yaml",
  ensure => link,
}

file {"/etc/puppet/hiera.yaml":
  source => "/vagrant/manifests/hiera.yaml",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 755,
}
####### END hiera install section ######


##### BEGIN puppetmaster install section ######
#                                        __
#                                       /\ \__
#  _____   __  __  _____   _____      __\ \ ,_\
# /\ '__`\/\ \/\ \/\ '__`\/\ '__`\  /'__`\ \ \/
# \ \ \L\ \ \ \_\ \ \ \L\ \ \ \L\ \/\  __/\ \ \_
#  \ \ ,__/\ \____/\ \ ,__/\ \ ,__/\ \____\\ \__\
#   \ \ \/  \/___/  \ \ \/  \ \ \/  \/____/ \/__/
#    \ \_\           \ \_\   \ \_\
#     \/_/            \/_/    \/_/
#
service {"httpd":
  ensure => "running",
  enable => "true",
  require => Package['httpd'],
}

# these requests will be handled through httpd
service {"puppetmaster":
  ensure => "stopped",
  enable => "false",
}

# install passenger to host puppetmaster in apache
exec {'install_passenger_gem':
  command     => "/usr/bin/gem install rack && /usr/bin/gem install passenger -v 4.0.59",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  refreshonly => true,
  notify      => Exec['install_passenger'],
}

# passenger apache requires c and c++ compiler
package { "gcc-c++":
    ensure => "installed"
}

exec {'install_passenger':
  command     => "/usr/bin/passenger-install-apache2-module -a",
  creates     => "/usr/lib/ruby/gems/1.8/gems/passenger-4.0.59/buildout/apache2/mod_passenger.so",
  path        => ["/bin","/usr/bin","/sbin","/usr/sbin"],
  require     => [ Exec['install_passenger_gem'], Package['rubygems'] ],
}

# create the directory for the puppet server rack application
# to live in
file {["/usr/share/puppet/rack",
       "/usr/share/puppet/rack/puppetmasterd",
       "/usr/share/puppet/rack/puppetmasterd/public",
       "/usr/share/puppet/rack/puppetmasterd/tmp",
       ]:
         ensure => directory,
         owner  => puppet,
         group  => puppet,
         mode   => 755,
}

# Rack application configuration, installed via puppet install
file {"/usr/share/puppet/rack/puppetmasterd/config.ru":
  source => "/usr/share/puppet/ext/rack/config.ru",
  ensure => file,
  owner  => puppet,
  group  => puppet,
  mode   => 750,
  require => [ File['/usr/share/puppet/rack/puppetmasterd'], File['/etc/puppet/puppet.conf']],
  notify => Service['httpd'],
}

# Configuration for apache to run the rack application
file {"/etc/httpd/conf.d/puppetmaster.conf":
  source => "/vagrant/manifests/httpd_puppet.conf",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 750,
  require => Package['httpd'],
}

# keep the perms open on puppet.conf so the apache
# proc running can read it
file {"/etc/puppet/puppet.conf":
  source => "/vagrant/manifests/master_puppet.conf",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 755,
}

file {"/etc/puppet/environments/production":
  ensure => directory,
  owner  => puppet,
  group  => puppet,
  mode   => 755,
}

# we are using environments so get rid of these dirs
# so they don't cause any confusion
file {["/etc/puppet/manifests","/etc/puppet/modules","/etc/puppet/environments/example_env"]:
  ensure => absent,
  force => true,
}
