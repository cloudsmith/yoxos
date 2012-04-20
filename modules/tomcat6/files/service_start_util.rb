require 'base64'

service = Base64.decode64(ARGV.shift())

rd, wr = IO.pipe()

# execute puppet apply
pid = fork() do
  wr.close()
  $stdin.reopen(rd)
  exec(*%w{puppet apply --no-report --detailed-exitcodes})
end
rd.close()

# pass the manifest to the puppet apply command via its standard input
wr.write("service { '#{service}': ensure => running }")
wr.close()

Process.waitpid(pid)

exit(($?.exitstatus & 6) == 0 ? 0 : 1)
