require 'uri'

URI_RESERVED_PATTERN = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")

# escape the supplied argument such that it is suitable for inlusion in an URI
Puppet::Parser::Functions::newfunction(:uri_escape, :type => :rvalue) do |args|
  token = args.shift()
  token.nil? ? nil : URI.escape(token, URI_RESERVED_PATTERN)
end
