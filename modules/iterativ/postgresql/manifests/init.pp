class postgresql {

  package {'libpq-dev':
    ensure => installed
  }

  package { 'postgresql-9.1':
    ensure => installed
  }

  # this hack is needed so that the default encoding is UTF-8
  # see: http://projects.puppetlabs.com/issues/4695#note-12
  exec { "utf8 postgres":
    command => "/usr/bin/pg_dropcluster --stop 9.1 main && pg_createcluster --start --encoding=UTF-8 --locale=en_US.UTF-8 9.1 main",
    unless  => "sudo -u postgres psql -t -c '\\l' | grep template0 | grep -q UTF",
    require => Package['postgresql-9.1'],
    path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
  }

  file { 'postgresql_conf_folder':
    path => "/etc/postgresql/9.1/main/",
    owner => postgres,
    group => postgres,
    ensure => directory,
    require => Package["postgresql-9.1"]
  }

  file { 'pg_hba.conf':
    path => "/etc/postgresql/9.1/main/pg_hba.conf",
    owner => postgres,
    group => postgres,
    ensure => present,
    content => template("postgresql/conf/pg_hba.conf"),
    require => File["postgresql_conf_folder"]
  }

  file { 'postgresql.conf':
    path => "/etc/postgresql/9.1/main/postgresql.conf",
    owner => postgres,
    group => postgres,
    ensure => present,
    content => template("postgresql/conf/postgresql.conf"),
    require => File["postgresql_conf_folder"]
  }

  # set the SHMMAX setting of the machine to 512 MB
  exec { "linux_shared_mem":
    command => "/sbin/sysctl -w kernel.shmmax=536870912",
    require => File_line["linux_shared_mem_reboot"]
  }

  file_line { 'linux_shared_mem_reboot':
    line => 'kernel.shmmax=536870912',
    path => '/etc/sysctl.conf',
  }

  service {"postgresql":
    ensure => running,
    enable => true,
    hasstatus => true,
    require => [Package["postgresql-9.1"], Exec["linux_shared_mem"]],
    subscribe => [File["pg_hba.conf"], File["postgresql.conf"]]
  }
}
