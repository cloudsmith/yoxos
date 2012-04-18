require 'puppet/external/pson/common'
require 'puppet/external/pson/version'
require 'puppet/external/pson/pure'

# turn the suplied JSON data into a string having the ini file format
Puppet::Parser::Functions::newfunction(:format_as_ini_file, :type => :rvalue) do |args|
  settings = {}
  # treat all input arguments as JSON data
  args.each() do |json|
    begin
      # parse the json data and merge the result to the hash holding the configuration settings
      PSON.parse(json).each_pair() do |key, value|
	values = settings[key] || {}
	settings[key] = values.merge(value)
      end
    rescue => e
      raise ArgumentError, "specified parameter is not a valid JSON configuration data: #{json}#{$/}"
    end
  end

  # convert the configuration settings collected in the hash to the ini file format string
  result = ''
  settings.keys().sort().each() do |section|
    result << "[#{section}]#{$/}"
    values = settings[section]
    values.keys().sort().each() do |key|
      result << "#{key} = #{values[key]}#{$/}"
    end
  end

  result
end
