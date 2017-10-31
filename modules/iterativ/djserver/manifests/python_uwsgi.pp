class djserver::python_uwsgi {

  require djserver

  package { ['python', 'python-dev', 'python-pip', 'python-setuptools', 'python-virtualenv']:
    ensure => installed
  }

  package { ['python3', 'python3-dev', 'python3-pip', 'python3-setuptools', 'python3-virtualenv']:
    ensure => installed
  }

# TODO: still needed for 2.7??
  file { '/usr/lib/python2.7/decimal.py':
    ensure  => present,
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

# uwsgi
  package { ['uwsgi', 'uwsgi-plugin-python']:
    ensure => present
  }

}
