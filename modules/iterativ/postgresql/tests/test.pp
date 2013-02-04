include postgresql

postgresql::role { "shop":
  ensure    => present,
  password  => "test"
}

postgresql::database { "shopdb":
  ensure => present,
  owner => "shop"
}
