class tomcat6::variables {
	# TODO verify the locataion across distros
	$home_dir = $::operatingsystem ? {
		'Ubuntu' => '/usr/share/tomcat6',
		'CentOS' => '/usr/share/tomcat6',
		'Debian' => '/usr/share/tomcat6',
		default => '/usr/share/tomcat6',
	}

	# TODO verify the locataion across distros
	$config_file = $::operatingsystem ? {
		'Ubuntu' => '/etc/sysconfig/tomcat6',
		'CentOS' => '/etc/sysconfig/tomcat6',
		'Debian' => '/etc/sysconfig/tomcat6',
		default => '/etc/sysconfig/tomcat6',
	}

	$start_util = '/usr/local/lib/service_start_util.rb'
	$wait_util = '/usr/local/lib/wait_for_server.rb'
}
