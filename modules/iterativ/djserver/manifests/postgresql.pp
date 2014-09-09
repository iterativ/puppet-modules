class djserver::postgresql {

  class { 'postgresql::server':
  }

  class { 'postgresql::server::postgis':
  }

  postgresql::server::pg_hba_rule { "allow local access via password":
    description => "allow local access via password",
    type => 'local',
    database => 'all',
    user => 'all',
    auth_method => 'md5',
    order => '002'
  }

# best practices for postgresql.conf
  postgresql::server::config_entry { 'shared_buffers':
  # ca. 1/8 vom RAM. Zwischen 256MB und 2GB, auf VPS natürlich entsprechend
    value => '128MB',
  }

  postgresql::server::config_entry { 'work_mem':
  # work_mem zeigt an wieviel speicher ein einzelnes teil-query (sort) verwenden kann
  # umso komplexer die queries sind desto höher sollte work_mem sein
  # PostGIS verursacht auch häufig komplexe queries
    value => '4MB',
  }

  postgresql::server::config_entry { 'maintenance_work_mem':
  # wird benutzt beim index erstellen etc.
    value => '64MB',
  }

  postgresql::server::config_entry { 'synchronous_commit':
  # default für synchronous_commit ist on. Normalerweise kann man nur 0.2s Daten verlieren
  # Empfehlung ist es auf off zu stellen
    value => 'off',
  }

  postgresql::server::config_entry { 'checkpoint_segments':
  # default-wert von checkpoint_segments ist 3, das ist wenig
  # platzverbrauch ca checkpoint_segments * 2.5
  # nach einem crash muss das ganze WAL wieder reingelesen werden -> Zeit für reboot steigt
    value => 16,
  }

  postgresql::server::config_entry { 'checkpoint_timeout':
  # default ist 5min. Bei Standardanwendungen ist 30min nicht schlecht
    value => '30min',
  }

  postgresql::server::config_entry { 'checkpoint_completion_target':
    value => 0.8,
  }

  postgresql::server::config_entry { 'effective_cache_size':
  # Niedriges effective_cache_size führt zu vielen Random Reads
  # Höheres effective_cache_size -> mehr Index-Scans
    value => '256MB',
  }

#log settings von Christophe Pettus
  postgresql::server::config_entry { 'log_destination':
    value => "csvlog",
  }
  postgresql::server::config_entry { 'log_directory':
    value => '/var/log/postgresql/',
  }
  postgresql::server::config_entry { 'logging_collector':
    value => 'on',
  }
  postgresql::server::config_entry { 'log_filename':
    value => 'postgres-%Y-%m-%d_%H%M%S',
  }
  postgresql::server::config_entry { 'log_rotation_age':
    value => '1d',
  }
  postgresql::server::config_entry { 'log_rotation_size':
    value => '1GB',
  }
  postgresql::server::config_entry { 'log_min_duration_statement':
    value => '250ms',
  }
  postgresql::server::config_entry { 'log_checkpoints':
    value => 'on',
  }
  postgresql::server::config_entry { 'log_connections':
    value => 'on',
  }
  postgresql::server::config_entry { 'log_disconnections':
    value => 'on',
  }
  postgresql::server::config_entry { 'log_lock_waits':
    value => 'on',
  }
  postgresql::server::config_entry { 'log_temp_files':
    value => '0',
  }

# base dependencies
  $base_libs = ['libjpeg62', 'libjpeg62-dev', 'libfreetype6',
    'libfreetype6-dev', 'libpcre3-dev', 'zlib1g-dev',
    'libxml2', 'libxml2-dev', 'libssl-dev', 'libpq-dev']

# django server dependencies
  package { $base_libs:
    ensure  => installed,
    require => Class['djserver']
  }

  class { '::rabbitmq':
    service_manage    => false,
    port              => '5672',
    delete_guest_user => true,
  }

}