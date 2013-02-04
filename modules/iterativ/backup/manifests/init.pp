class backup {
  define offsite_backup($mydrive_user_login, $mydrive_password) {
    file { "/backupoffsite":
      ensure => directory,
      owner => "root",
      group => "root",
      mode => 755
    }

    file { "/usr/local/bin/make_backup.py":
      ensure => present,
      owner => "root",
      group => "root",
      mode => 755,
      content => template("backup/make_backup.py.erb")
    }

    package { "Python_WebDAV_Library":
      ensure => installed,
      provider => 'pip'
    }

    cron { "offsite-backup":
      command => "/usr/local/bin/make_backup.py",
      user => "root",
      minute => 20,
      hour => 2,
      require => [File["/usr/local/bin/make_backup.py"]],
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
      minute => 03,
      hour => 2,
      require => File["/usr/local/bin/backup_postgres.py"]
    }
  }
}
