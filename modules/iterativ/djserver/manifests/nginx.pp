class djserver::nginx($disable_default=false,) {

  require djserver

  # install nginx
  package { 'nginx':
    ensure  => installed,
    require => [Class['locales'], User['www-data']]
  }

  package { 'letsencrypt':
    ensure => installed,
    require => Package['nginx']
  }

  file { '/tmp/letsencrypt-auto':
    ensure => 'directory',
    mode => '0777'
  }

  # get rid of the default site
  file { '/etc/nginx/sites-available/default':
    ensure  => absent,
    require => Package['nginx']
  }
  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    require => Package['nginx']
  }

  file { 'nginx.conf':
    notify  => Service["nginx"],
    path    => '/etc/nginx/nginx.conf',
    ensure  => present,
    content => template("djserver/nginx.conf.erb"),
    require => Package[nginx]
  }

  file { 'mime.types':
    notify  => Service["nginx"],
    path    => '/etc/nginx/mime.types',
    ensure  => present,
    content => template("djserver/mime.types.erb"),
    require => Package[nginx]
  }

  service { 'nginx':
    ensure  => running,
    enable  => true,
    require => [File["nginx.conf", "mime.types"], Package['apache2']],
  }

  package { 'apache2':
    ensure => absent
  }

  # user/group
  group { 'www-data':
    ensure => present,
  }
  user { 'www-data':
    ensure     => present,
    managehome => true,
    groups     => ['adm','www-data'],
    require    => Group['www-data']
  }

  # nginx config change listener
  exec { "restart-nginx":
    command     => "/etc/init.d/nginx restart",
    refreshonly => true,
  }

  cron { 'letsencrypt_renew':
    command => "letsencrypt renew",
    user    => root,
    hour    => 2,
    minute  => 30
  }

  cron { 'reload_nginx':
    command => "/etc/init.d/nginx reload",
    user    => root,
    hour    => 2,
    minute  => 35
  }
}
