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

  # for the global python we will always use virtualenv to handle python dependencies
  # we will never install python libraries globally on the system
  # do ensure that we do the following steps:
  # 1. install python-setuptools (it contains easy_install)
  # 2. install the newest pip globally via easy_install (to upgrade virtualenv in the future)
  # 3. install virtualenv via easy_install globally on the system
  # we do this to have the newest version of virtualenv available it is needed to handel mysql-python via pip install:
  # http://stackoverflow.com/questions/12993708/unable-to-install-mysql-python
  # need for mysql install

  # ACHTUNG: falls eine Version von pip, setuptools und/oder virtualenv geändert wird, müssen ev. die virtualenv neu
  # erstellt werden!!!
  # ensure that python is installed
  package { ['python', 'python-dev', 'python-pip', 'python-setuptools']:
    ensure => installed
  }

  package { 'pip':
    provider => pip,
    ensure => '1.3.1',
    require => Package['python-pip'],
  }

  package { 'setuptools':
    provider => pip,
    ensure => '0.9.1',
    require => Package['pip'],
  }

  package { 'distribute':
    provider => pip,
    ensure => '0.7.3',
    require => Package['pip'],
  }

  package { 'virtualenv':
    provider => pip,
    ensure => '1.9.1',
    require => Package['pip'],
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
