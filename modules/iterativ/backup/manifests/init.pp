class backup {
  define duplicity_backup_s3($aws_access_key_id, $aws_secret_access_key, $passphrase, $backup_destination, $inclist, $exclist) {
    package { "duplicity":
      ensure => installed,
    }

    package { "boto":
      ensure => installed,
      provider => 'pip',
      require => Package["duplicity"],
    }

    package { "s3cmd":
      ensure => installed,
    }

    file { "/etc/s3cmd.conf":
      ensure => present,
      owner => root,
      group => root,
      mode => 640,
      content => template("backup/s3cmd.conf.erb"),
      require => Package["s3cmd"],
    }

    file { "/usr/local/bin/duplicity-backup.sh":
      ensure => present,
      owner => root,
      group => root,
      mode => 755,
      content => template("backup/duplicity-backup.sh"),
      require => Package["boto"],
    }

    file { "/etc/duplicity-backup.conf":
      ensure => present,
      owner => root,
      group => root,
      mode => 640,
      content => template("backup/duplicity-backup.conf.erb"),
      require => File["/usr/local/bin/duplicity-backup.sh"],
    }

    cron { "duplicity-backup-cron":
      command => "/usr/local/bin/duplicity-backup.sh -c /etc/duplicity-backup.conf --backup",
      user => "root",
      minute => 20,
      hour => 2,
      require => [File["/etc/duplicity-backup.conf"], File["/etc/s3cmd.conf"]], 
    }
  }

  define postgres_backup {
    file { "/var/backups/postgres":
      ensure => directory,
      owner => "postgres",
      group => "postgres",
      mode => 755
    }

    # copies the backup script into the specified folder
    file { "/usr/local/bin/backup_postgres.py":
      ensure => present,
      owner => root,
      group => root,
      mode => 755,
      content => template("backup/backup_postgres.py"),
      require => File["/var/backups/postgres"]
    }

    cron { "backup-postgres":
      command => "/usr/local/bin/backup_postgres.py",
      user => "postgres",
      minute => 01,
      hour => 2,
      require => File["/usr/local/bin/backup_postgres.py"]
    }
  }
}
