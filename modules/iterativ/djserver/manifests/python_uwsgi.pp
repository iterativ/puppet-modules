class djserver::python_uwsgi {

  require djserver

  package { ['python3', 'python3-dev', 'python3-pip', 'python3-setuptools', 'python3-virtualenv', 'virtualenv']:
    ensure => installed
  }

  # make python semaphores working:
  # see: http://stackoverflow.com/questions/2009278/python-multiprocessing-permission-denied
  file_line { 'shm mountable':
    line => 'none /dev/shm tmpfs rw,nosuid,nodev,noexec 0 0',
    path => '/etc/fstab',
  }

  exec { 'mount shm':
    command => '/bin/mount -a /dev/shm/',
    require => File_line['shm mountable'],
  }

  # uwsgi
  #package { ['uwsgi', 'uwsgi-plugin-python']:
  #  ensure => present
  #}

  package { ['uwsgi']:
    ensure => "2.0.15",
    provider => 'pip3'
  }

  # install uwsgi.service config file
  file { "/etc/systemd/system/uwsgi.service":
    ensure  => present,
    content => template("djserver/uwsgi.service.conf"),
    require => Package['uwsgi']
  }

  # get rid of the init.d uwsgi start script colliding with systemctl uwsgi.service
  file { '/etc/init.d/uwsgi':
    ensure  => absent,
    require => Package['uwsgi']
  }

  # get rid of init.d style uwsgi app dirs
  # file { "/etc/uwsgi/apps-available":
  #   ensure  => absent,
  #   require => Package['uwsgi']
  # }
  # file { "/etc/uwsgi/apps-enabled":
  #   ensure  => absent,
  #   require => Package['uwsgi']
  # }

  # enable and start uwsgi.service once uwsgi init.d script is removed
  service { "uwsgi.service":
    provider => systemd,
    ensure => running,
    enable => true,
    require => File['/etc/init.d/uwsgi']
  }

}
