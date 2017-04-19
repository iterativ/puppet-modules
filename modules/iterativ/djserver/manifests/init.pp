class djserver {

  include djserver::locales

# utils
  package { ['locate', 'wget', 'vim', 'tmux']:
    ensure => installed
  }

  package { "ntp":
    ensure => installed
  }

  # keep ssh agent forward for sudo
  file { '/etc/sudoers.d/99-keep-ssh-auth-sock-env':
    ensure  => present,
    content => template("djserver/sudo_keep_ssh_auth_sock.erb")
  }

  file { '/root/.ssh':
    ensure  => 'directory',
    owner  => 'root',
    group  => 'root',
  }

  file { '/root/.ssh/known_hosts':
    ensure  => 'present',
    replace => 'no',
    content => '',
    mode    => '0644',
    require => File['/root/.ssh']
  }

  exec { "add_github_key":
    path => ["/usr/bin/", "/bin/"],
    command => "ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts",
    user => root,
    unless => "/bin/grep github.com /root/.ssh/known_hosts",
    require => File['/root/.ssh/known_hosts']
  }

  exec { "add_bitbucket_key":
    path => ["/usr/bin/", "/bin/"],
    command => "ssh-keyscan -t rsa bitbucket.org >> /root/.ssh/known_hosts",
    user => root,
    unless => "/bin/grep bitbucket.org /root/.ssh/known_hosts",
    require => File['/root/.ssh/known_hosts']
  }

  service { "ntp":
    ensure  => running,
    enable  => true,
    require => Package['ntp']
  }
}
