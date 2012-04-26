class yoxos(
	$data_root = '/opt/yoxos/accountadminworkspace',
	$couchdb_admin_login = 'yoxoscouchadmin',
	$couchdb_admin_password = 'yoxoscouch'
) {
	include tomcat6
	include tomcat6::variables
	include apache2
	include apache2::variables

	class { 'yoxos::couchdb':
		admin_username => $couchdb_admin_login,
		admin_password => $couchdb_admin_password
	}

	$setup_util = '/usr/local/lib/yoxos_setup_util.rb'

	$couchdb_admin_login_uri_escaped = uri_escape($couchdb_admin_login)
	$couchdb_admin_password_uri_escaped = uri_escape($couchdb_admin_password)

	exec { "create-${data_root}":
		unless => "test -d \"${data_root}\"",
		command => "mkdir -p \"${data_root}\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
	}

	file { $data_root:
		ensure => directory,
		owner => tomcat,
		group => tomcat,
		mode => 0755,
		require => [Package['tomcat6'], Exec["create-${data_root}"]],
		notify => Service['tomcat6'],
	}

	file { "${tomcat6::variables::config_file}.base":
		source => $tomcat6::variables::config_file,
		replace => false,
		owner => root,
		group => root,
		mode => 0644,
		require => Package['tomcat6'],
	}

	file { "${tomcat6::variables::config_file}.yoxos":
		content => template('yoxos/tomcat.config.erb'),
		owner => root,
		group => root,
		mode => 0644,
		require => Package['tomcat6'],
	}

	exec { 'tomcat-config':
		unless => "cat \"${tomcat6::variables::config_file}\".{base,yoxos} | diff - \"${tomcat6::variables::config_file}\"",
		command => "cat \"${tomcat6::variables::config_file}\".{base,yoxos} > \"${tomcat6::variables::config_file}\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => File["${tomcat6::variables::config_file}.base", "${tomcat6::variables::config_file}.yoxos"],
		notify => Service['tomcat6'],
	}

	file { "${tomcat6::variables::home_dir}/webapps/accountadmin.war":
		source => 'puppet:///modules/yoxos/accountadmin.war',
		owner => root,
		group => root,
		mode => 0644,
		require => Package['tomcat6'],
	}

	file { $setup_util:
		source => 'puppet:///modules/yoxos/yoxos_setup_util.rb',
		owner => root,
		group => root,
		mode => 0644,
	}

	exec { 'couchdb-ready':
		command => "ruby \"${tomcat6::variables::wait_util}\" \"localhost\" \"5984\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		refreshonly => true,
		require => File[$tomcat6::variables::wait_util],
		subscribe => Service['couchdb'],
	}

	exec { 'setup-yesa-documents':
		unless => "ruby \"${setup_util}\" get /accountadmin/setup",
		command => "ruby \"${setup_util}\" put \"/accountadmin/setup?username=${couchdb_admin_login_uri_escaped}&password=${couchdb_admin_password_uri_escaped}&overwrite=true\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => [Service['tomcat6', 'couchdb'], File["${tomcat6::variables::home_dir}/webapps/accountadmin.war"], Exec['tomcat-config', 'tomcat6-ready', 'couchdb-ready']],
	}

	file { "${apache2::variables::config_include_dir}/yoxos.conf":
		ensure => present,
		content => template('yoxos/yoxos.httpd.conf.erb'),
		owner => root,
		group => root,
		mode => 0644,
		require => [Package['apache2'], Service['tomcat6']],
		notify => Service['apache2'],
	}

	file { "${data_root}/../slice.properties":
		ensure => present,
		content => template('yoxos/slice.properties.erb'),
		owner => root,
		group => root,
		mode => 0644,
		require => File[$data_root],
	}

	exec { 'create-yesa-slice':
		# unless => "ruby \"${setup_util}\" get /accountadmin/listSlices",
		command => "ruby \"${setup_util}\" post \"/accountadmin/createSlice?username=${couchdb_admin_login_uri_escaped}&password=${couchdb_admin_password_uri_escaped}\" \"${data_root}/../slice.properties\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => [Exec['setup-yesa-documents'], File["${data_root}/../slice.properties"]],
	}
}
