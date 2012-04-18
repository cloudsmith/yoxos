require 'net/http'
require 'puppet/external/pson/common'
require 'puppet/external/pson/version'
require 'puppet/external/pson/pure'

def send_request(method, request, data = nil)
  method = ('request_' << method).to_sym
  response = Net::HTTP.new('localhost', 8080).send(method, request, data)
  exit 1 unless response.is_a?(Net::HTTPOK)
  PSON.parse(response.body)
end

def wait_for_completion(uri)
  begin
    response = Net::HTTP.get_response(uri)
    exit 1 unless response.is_a?(Net::HTTPOK)
    data = PSON.parse(response.body)
  end while data['state'].casecmp('In Progress') == 0 && sleep(2) >= 0

  data
end

command = ARGV.shift()
request = ARGV.shift()

case command
  when 'get'
    # check if the setup has already been run
    data = send_request(command, request)

    exit data['setup'] ? 0 : 1
  when 'put'
    # run the setup
    data = send_request(command, request)
    data = wait_for_completion(URI(data['information']))

    exit data['status'].casecmp('Ok') == 0 ? 0 : 1
  else
    raise "uknown command #{command}"
end
