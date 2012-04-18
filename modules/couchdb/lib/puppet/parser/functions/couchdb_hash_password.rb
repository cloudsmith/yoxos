require 'digest/sha1'

SMALLINT_RANGE = 2 ** 16

# create a password hash of the suplied password in the same way couchdb does that
Puppet::Parser::Functions::newfunction(:couchdb_hash_password, :type => :rvalue) do |args|
  password = args.shift()
  raise ArgumentError, "password must be specified" if password.nil?

  salt = args.shift()
  if salt.nil? || salt.empty?
     # compose a random salt string if not specified
     salt = 8.times.map { "%04x" % rand(SMALLINT_RANGE) }.join()
  else
     # validate (and downcase) the specified salt string
     raise ArgumentError, "salt must be a 32 characters long hexadecimal string" unless salt =~ /^[0-9A-Fa-f]{32}$/
     salt = salt.downcase()
  end

  digester = Digest::SHA1.new()

  digester.update(password)
  digester.update(salt)

  '-hashed-' << digester.hexdigest() << ',' << salt
end
