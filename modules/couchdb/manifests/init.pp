class couchdb(
	$install_dir = '/usr/local',
	$ini_file_settings = '{}'
) {
	include rubygems
	include rubygems::common_dependencies

	$couchdb_repository = 'git://git.apache.org/couchdb.git'
	$couchdb_verion = 'tags/1.2.0'

	$build_repository = 'git://github.com/iriscouch/build-couchdb.git'
	$build_dir = '/var/cache/build-couchdb'

	$build_dependencies = [
		'automake', 'libtool', 'perl', 'help2man', 'libcurl-devel', 'openssl-devel', 'zlib-devel'
	]

	package { 'git':
		ensure => latest,
	}

	package { [$build_dependencies]:
		ensure => latest,
	}

	package { 'rake':
		ensure => latest,
		provider => gem,
	}

	exec { 'git-clone-build-repository':
		command => "git clone \"${build_repository}\" \"${build_dir}\"",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		creates => "${build_dir}",
		require => Package['git'],
	}

	exec { 'git-update-build-submodules':
		onlyif => 'git submodule status | grep -q ^[-+]',
		command => 'git submodule update --init',
		cwd => "${build_dir}",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		require => Exec['git-clone-build-repository'],
	}

	exec { 'build-couchdb':
		command => "rake git='${couchdb_repository} ${couchdb_verion}' install='${install_dir}'",
		cwd => "${build_dir}",
		path => ['/usr/local/bin', '/bin', '/usr/bin'],
		creates => "${install_dir}/bin/couchdb",
		timeout => 0,
		require => Package['rake'],
		subscribe => [Exec['git-clone-build-repository', 'git-update-build-submodules'], Class['rubygems::common_dependencies'], Package[$build_dependencies]],
	}

	group { 'couchdb':
		ensure => present,
		system => true,
	}

	user { 'couchdb':
		ensure => present,
		gid => 'couchdb',
		system => true,
		home => "${install_dir}/var/lib/couchdb",
		managehome => false,
	}

	file { "${install_dir}/etc/couchdb/local.ini":
		content => format_as_ini_file(template('couchdb/local.json.erb'), $ini_file_settings),
		owner => 'couchdb',
		group => 'couchdb',
		mode => 0644,
		require => Exec['build-couchdb'],
	}

	file { '/etc/init.d/couchdb':
		ensure => link,
		target => "${install_dir}/etc/rc.d/couchdb",
	}

	file { '/etc/logrotate.d/couchdb':
		ensure => link,
		target => "${install_dir}/etc/logrotate.d/couchdb",
	}

	file { ["${install_dir}/var/lib/couchdb", "${install_dir}/var/log/couchdb", "${install_dir}/var/run/couchdb"]:
		owner => couchdb,
		group => couchdb,
		mode => 0755,
		require => Exec['build-couchdb'],
	}

	service { 'couchdb':
		ensure => running,
		enable => true,
		hasrestart => true,
		hasstatus => true,
		require => File["${install_dir}/var/lib/couchdb", "${install_dir}/var/log/couchdb", "${install_dir}/var/run/couchdb", '/etc/logrotate.d/couchdb'],
		subscribe => [Exec['build-couchdb'], File["${install_dir}/etc/couchdb/local.ini", '/etc/init.d/couchdb']],
	}
}
