class backup {
  define duplicity_backup_s3($aws_access_key_id, $aws_secret_access_key, $passphrase, $backup_destination, $inclist, $exclist) {
    package { "duplicity":
      ensure => installed,
    }

    file { "/usr/local/bin/duplicity-backup.sh":
      ensure => present,
      owner => root,
      group => root,
      mode => 755,
      content => template("backup/duplicity-backup.sh"),
      require => Package["duplicity"],
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
      require => [File["/etc/duplicity-backup.conf"]],
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

    file { "/usr/local/bin/rotate-backups-postgres.py":
      ensure => present,
      owner => root,
      group => root,
      mode => 755,
      content => template("backup/rotate-backups.py"),
    }

    file { "/root/.rotate-backupsrc":
      ensure => present,
      owner => root,
      group => root,
      mode => 644,
      content => template("backup/rotate-backups.conf"),
      require => File["/usr/local/bin/rotate-backups-postgres.py"],
    }

    cron { "rotate-backup-postgres":
      command => "/usr/local/bin/rotate-backups-postgres.py",
      user => "root",
      minute => 50,
      hour => 1,
      require => File["/usr/local/bin/rotate-backups-postgres.py"],
    }
  }

  define mysql_backup($mysql_user, $mysql_password, $mysql_ignore_db) {
    file { "/var/backups/mysql":
      ensure => directory,
      owner => "mysql",
      group => "mysql",
      mode => 755
    }

    file { "/etc/automysqlbackup":
      ensure => directory,
      owner => "mysql",
      group => "mysql",
      mode => 755
    }

    # copies the backup script into the specified folder
    file { "/usr/local/bin/automysqlbackup":
      ensure => present,
      owner => root,
      group => root,
      mode => 755,
      content => template("backup/automysqlbackup"),
      require => File["/var/backups/mysql"]
    }

    file { "/etc/automysqlbackup/server.conf":
      ensure => present,
      owner => root,
      group => root,
      mode => 600,
      content => template("backup/automysqlbackup.conf.erb")
    }

    cron { "mysql-backup":
      command => "/usr/local/bin/automysqlbackup /etc/automysqlbackup/server.conf",
      user => "root",
      minute => 01,
      hour => 2,
      require => [File["/etc/duplicity-backup.conf"]],
    }

  }
}