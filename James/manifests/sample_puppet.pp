host{"tiber": ip=> "172.28.128.6"}
host{"pmaster": ip=> "172.28.128.7"}
host{"cmaster": ip=> "172.28.128.8"}
host{"james": ip=> "172.28.128.9"}

package {"Download PuppetLab repo":
  name=>puppetlabs-release,
  provider=>rpm,
  ensure=>installed,
  #install_options => ['--nodeps'],
  source=>"http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm",
}

package { 'puppet':
      ensure => present,
      before => Package['Download PuppetLab repo'],
    }

