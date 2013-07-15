# Class: djbootstrap
#
# This module manages djbootstrap
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class djserver {

  include locales

  # install nginx
  package {'nginx':
    ensure => installed,
    require => [Class['locales'], User['www-data']]
  }

  # get rid of the default site
  file { '/etc/nginx/sites-available/default':
    ensure => absent,
    require => Package['nginx']
  }
  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
    require => Package['nginx']
  }

  file {'nginx.conf':
    notify => Service["nginx"],
    path => '/etc/nginx/nginx.conf',
    ensure => present,
    content => template("djserver/nginx.conf.erb"),
    require => Package[nginx]
  }

  file {'mime.types':
    notify => Service["nginx"],
    path => '/etc/nginx/mime.types',
    ensure => present,
    content => template("djserver/mime.types.erb"),
    require => Package[nginx]
  }

  file { "/usr/local/src/pipcheck.py":
    ensure => present,
    owner => "root",
    group => "root",
    content => template("djserver/pipcheck.py"),
  }

  service {'nginx':
    ensure => running,
    enable => true,
    require => [File["nginx.conf", "mime.types"], Package['apache2']],
  }

  package {'apache2':
    ensure => absent
  }

  # firewall
  package { ['vim', 'iptables-persistent', 'iptables']:
    ensure => installed
  }

  service {'iptables-persistent':
    ensure => running,
    enable => true,
    require => [File["rules.v4"], File["rules.v6"]],
  }

  file {'rules.v4':
    notify => Service["iptables-persistent"],
    path => '/etc/iptables/rules.v4',
    ensure => present,
    owner => "root",
    group => "root",
    content => template("djserver/iptables.rules.v4"),
    require => Package[iptables-persistent]
  }

  file {'rules.v6':
    notify => Service["iptables-persistent"],
    path => '/etc/iptables/rules.v6',
    ensure => present,
    owner => "root",
    group => "root",
    content => template("djserver/iptables.rules.v6"),
    require => Package[iptables-persistent]
  }


  # utils
  package { ['locate', 'wget']:
    ensure => installed
  }

  # ensure that python is installed
  package { ['python', 'python-dev']:
    ensure => installed
  }

  # for the global python we will always use virtualenv to handle python dependencies
  # we will never install python libraries globally on the system
  # do ensure that we do the following steps:
  # 1. install python-setuptools (it contains easy_install)
  # 2. install the newest pip globally via easy_install (to upgrade virtualenv in the future)
  # 3. install virtualenv via easy_install globally on the system
  # 4. remove python-setuptools
  # we do this to have the newest version of virtualenv available it is needed to handel mysql-python via pip install:
  # http://stackoverflow.com/questions/12993708/unable-to-install-mysql-python
  package { ['python-virtualenv', 'python-pip']:
    ensure => absent
  }

  package { 'python-setuptools':
    ensure => present
  }

  # need for mysql install
  exec { "install_virtualenv":
    command => "/usr/bin/easy_install -U virtualenv==1.9.1",
    require => Package['python-setuptools', 'python-virtualenv', 'python-pip'],
    user => root,
  }

  exec { "install_pip":
    command => "/usr/bin/easy_install -U pip==1.3.1",
    require => Package['python-setuptools', 'python-virtualenv', 'python-pip'],
    user => root,
  }

  exec { 'python-setuptools-remove':
    command => '/usr/bin/apt-get remove python-setuptools -y',
    require => Exec['install_virtualenv', 'install_pip'],
    user => root,
  }


  package { "ntp":
    ensure => installed
  }

  service { "ntp":
    ensure => running,
    enable => true,
    require => Package['ntp']
  }

  # TODO: still needed for 2.7
  file {'/usr/lib/python2.7/decimal.py':
    ensure => present,
    require => Package['python'],
    content => template("djserver/fix_decimal.py")
  }

  # make python semaphores workings:
  # see: http://stackoverflow.com/questions/2009278/python-multiprocessing-permission-denied
  file_line { 'shm mountable':
    line => 'none /dev/shm tmpfs rw,nosuid,nodev,noexec 0 0',
    path => '/etc/fstab',
  }

  exec { 'mount shm':
    command => '/bin/mount -a /dev/shm/',
    require => File_line['shm mountable'],
  }

  # user/group
  group {'www-data':
    ensure => present,
  }
  user {'www-data':
    ensure => present,
    managehome => true,
    groups => ['adm','www-data'],
    require => Group['www-data']
  }

  # nginx config change listener
  exec { "restart-nginx":
    command => "/etc/init.d/nginx restart",
    refreshonly => true,
  }

  package {'uwsgi-python':
    ensure => absent
  }

  package {'uwsgi':
    ensure => absent
  }

  package {'uwsgi-core':
    ensure => absent
  }
}
