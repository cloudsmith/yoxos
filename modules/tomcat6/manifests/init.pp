class tomcat6(
	$address = '127.0.0.1',
	$port = '8080',
	$management_port = '8005'
) {
	include patch
	include tomcat6::variables

	$package = $::operatingsystem ? {
		'Ubuntu' => 'tomcat6',
		'CentOS' => 'tomcat6',
		'Debian' => 'tomcat6',
		default => 'tomcat6',
	}

	$service = $package
	$service_base64_encoded = base64_encode($service)

	$script_patch = '/usr/local/lib/tomcat_script.patch'

	file { $script_patch:
		source => 'puppet:///modules/tomcat6/tomcat_script.patch',
		owner => root,
		group => root,
		mode => 0644,
	}

	file { $tomcat6::variables::start_util:
		source => 'puppet:///modules/tomcat6/service_start_util.rb',
		owner => root,
		group => root,
		mode => 0644,
	}

	file { $tomcat6::variables::wait_util:
		source => 'puppet:///modules/tomcat6/wait_for_server.rb',
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

	exec { 'tomcat6-start':
		unless => "ruby \"${tomcat6::variables::start_util}\" \"${service_base64_encoded}\"",
		command => "ruby \"${tomcat6::variables::wait_util}\" \"${address}\" \"${management_port}\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => [Exec['patch-script'], File[$tomcat6::variables::start_util, $tomcat6::variables::wait_util]],
	}

	exec { 'tomcat6-ready':
		command => "ruby \"${tomcat6::variables::wait_util}\" \"${address}\" \"${port}\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		refreshonly => true,
		require => File[$tomcat6::variables::wait_util],
	}

	service { 'tomcat6':
		name => $service,
		ensure => running,
		enable => true,
		hasrestart => true,
		hasstatus => true,
		require => Exec['tomcat6-start'],
		subscribe => Package['tomcat6'],
		notify => Exec['tomcat6-ready'],
	}
}
