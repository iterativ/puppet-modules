# Install PostGIS

class postgis {
  package { ['g++', 'binutils', 'gdal-bin', 'libproj-dev', 'postgresql-server-dev-9.1', 'postgresql-client', 'libgeos-3.2.2']:
    ensure => installed;
  'libgeos-3.1.0':
    ensure => absent
  }

  package { 'postgresql-9.1-postgis':
    ensure => installed
  }

  file { '/usr/share/postgis':
    ensure => directory,
    owner => "root", group => "root", mode => 755,
  }

  file { '/usr/share/postgis/create_template_postgis.sh':
    mode => '755',
    owner => 'root',
    group => 'root',
    source => '/etc/puppet/modules/postgis/files/postgis/create_template_postgis.sh',
    require => [Package['postgresql-9.1-postgis'], File['/usr/share/postgis']],
  }

  exec { "create_postgis_template":
    command => "/usr/share/postgis/create_template_postgis.sh",
    user => 'postgres',
    unless => "/usr/bin/psql -l | grep template_postgis",
    require => File['/usr/share/postgis/create_template_postgis.sh'],
  }
}
