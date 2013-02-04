# install the scout app: scoutapp.com

class scoutapp {

	postgresql::role { "scoutapp":
	    ensure    => present,
	    password  => "swT12gybx2H",
	    require => Class["postgresql"]
	}

    package {[ 'sysstat', 'ruby-dev', 'build-essential' ]: 
        	ensure => installed
    }

	package {[ 'scout', 'pg' ]:
			ensure   => 'installed',
			provider => 'gem',
			require => [Package['ruby-dev'], Package['build-essential']]
	}

  	# set up the cronjob that runs the agent every minute
	cron {
	  'scout':
	    command => "/var/lib/gems/1.8/bin/scout 96eed6e6-1f02-4d2b-9991-15566ff0c026";
	}
}
