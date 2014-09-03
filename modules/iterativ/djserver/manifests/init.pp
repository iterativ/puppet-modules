class djserver {

  include djserver::locales

# utils
  package { ['locate', 'wget', 'vim', 'tmux']:
    ensure => installed
  }

  package { "ntp":
    ensure => installed
  }

  service { "ntp":
    ensure  => running,
    enable  => true,
    require => Package['ntp']
  }
}
