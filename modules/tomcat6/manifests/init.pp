class tomcat6 {
	include patch

	$package = $::operatingsystem ? {
		'Ubuntu' => 'tomcat6',
		'CentOS' => 'tomcat6',
		'Debian' => 'tomcat6',
		default => 'tomcat6',
	}

	$service = $package

	$script_patch = '/usr/local/lib/tomcat_script.patch'

	file { $script_patch:
		source => 'puppet:///modules/tomcat6/tomcat_script.patch',
		owner => root,
		group => root,
		mode => 0644,
	}

	package { 'tomcat6':
		name => $package,
		ensure => latest,
	}

	exec { 'patch-script':
		unless => "patch --dry-run --reverse --force --quiet --input=\"${script_patch}\"",
		command => "patch --force --quiet --input=\"${script_patch}\"",
		cwd => '/usr/sbin',
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => [Package['tomcat6'], Class['patch'], File[$script_patch]],
	}

	service { 'tomcat6':
		name => $service,
		ensure => running,
		enable => true,
		hasrestart => true,
		hasstatus => true,
		subscribe => [Package['tomcat6'], Exec['patch-script']],
	}
}
