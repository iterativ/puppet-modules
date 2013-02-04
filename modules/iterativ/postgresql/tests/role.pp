include postgresql

postgresql::role { "lak":
  ensure    => present,
  password  => "test"
}
