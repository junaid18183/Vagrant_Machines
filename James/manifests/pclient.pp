file {"/etc/puppet/puppet.conf":
  source => "/vagrant/manifests/client_puppet.conf",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 750,
}

file {"/etc/profile.d/ps1.sh":
  source => "/vagrant/manifests/ps1.sh",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 755,
}


file {["/etc/facter/","/etc/facter/facts.d"]:
  ensure => directory,
  owner  => root,
  group  => root,
  mode   => 750,
}

file {"/etc/facter/facts.d/inventory.txt":
  content => "site=co",
  ensure => file,
  owner  => root,
  group  => root,
  mode   => 750,
  require => File["/etc/facter/facts.d"],
}
