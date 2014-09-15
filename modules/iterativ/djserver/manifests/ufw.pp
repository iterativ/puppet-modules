class djserver::ufw {

  require djserver

  # these settings produce the following config:
  # ufw allow 22/tcp
  # ufw enable
  # ufw status

  include ufw

  ufw::allow { "allow-ssh-from-all":
    port => 22,
  }

  ufw::allow { "allow-http-from-all":
    port => 80,
  }

  ufw::allow { "allow-https-from-all":
    port => 443,
  }

}
