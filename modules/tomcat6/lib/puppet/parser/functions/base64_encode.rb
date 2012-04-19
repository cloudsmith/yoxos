require 'base64'

# base64 encode the supplied string
Puppet::Parser::Functions::newfunction(:base64_encode, :type => :rvalue) do |args|
  string = args.shift()
  string.nil? ? nil : Base64.encode64(string).gsub(/[\r\n]/, '')
end
