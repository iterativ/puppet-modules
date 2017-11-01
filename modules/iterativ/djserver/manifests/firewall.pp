class djserver::firewall {

  require djserver

  # firewall
  package { ['iptables-persistent', 'iptables']:
    ensure => installed
  }

  service { 'netfilter-persistent':
    ensure  => running,
    enable  => true,
    require => [File["rules.v4"], File["rules.v6"]],
  }

  file { 'rules.v4':
    notify  => Service["netfilter-persistent"],
    path    => '/etc/iptables/rules.v4',
    ensure  => present,
    owner   => "root",
    group   => "root",
    content => template("djserver/iptables.rules.v4"),
    require => Package[iptables-persistent]
  }

  file { 'rules.v6':
    notify  => Service["netfilter-persistent"],
    path    => '/etc/iptables/rules.v6',
    ensure  => present,
    owner   => "root",
    group   => "root",
    content => template("djserver/iptables.rules.v6"),
    require => Package[iptables-persistent]
  }
}
