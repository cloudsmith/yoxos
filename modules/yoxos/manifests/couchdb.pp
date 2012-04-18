class yoxos::couchdb::include(
	$admin_username,
	$admin_password_hash
) {
	class { '::couchdb':
		ini_file_settings => template('yoxos/couchdb.json.erb'),
	}
}

class yoxos::couchdb(
	$admin_username = 'couchadmin',
	$admin_password = 'couch',
	$password_salt = '16821cb74f278d23d49fb9e160804f05'
) {
	class { 'yoxos::couchdb::include':
		admin_username => $admin_username,
		admin_password_hash => couchdb_hash_password($admin_password, $password_salt),
	}
}
