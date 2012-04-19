require 'base64'

service = Base64.decode64(ARGV.shift())

manifest = "service { '#{service}': ensure => running }"

rd, wr = IO.pipe()

# execute puppet apply
pid = fork() do
  wr.close()
  $stdin.reopen(rd)
  exec(*%w{puppet apply --no-report --detailed-exitcodes})
end
rd.close()

# pass the manifest to the puppet apply command via its standard input
wr.write(manifest)
wr.close()

Process.waitpid(pid)

exit(($?.exitstatus & 6) == 0 ? 0 : 1)
