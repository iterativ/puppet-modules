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

  # install uwsgi
  package {'uwsgi':
    ensure => installed,
    require => User['www-data']
  }

  package {'uwsgi-plugin-python':
    ensure => installed,
    require => Package['uwsgi']
  }

  # utils
  package { ['locate', 'wget']:
    ensure => installed
    }        
    # python and django project prerequisites
    package { ['python', 'python-dev', 'python-setuptools', 'python-virtualenv', 
    'python-pip']:
      ensure => installed
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

    # uwsgi config change listener
    exec { "restart-uwsgi":
      command => "/etc/init.d/uwsgi restart",
      refreshonly => true,
    }

}
