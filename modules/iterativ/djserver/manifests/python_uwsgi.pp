class djserver::python_uwsgi {

  require djserver

  package { ['python3', 'python3-dev', 'python3-pip', 'python3-setuptools', 'python3-virtualenv']:
    ensure => installed
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

  # uwsgi
  package { ['uwsgi', 'uwsgi-plugin-python']:
    ensure => present
  }

  # get rid of the default site
  file { '/etc/init.d/uwsgi':
    ensure  => absent,
    require => Package['uwsgi']
  }

}
