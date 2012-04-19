require 'socket'
require 'timeout'

server = ARGV.shift()
port = ARGV.shift()
wait_time = ARGV.shift()

wait_time = wait_time.nil? ? 300.0 : Float(wait_time)

deadline = Time.now() + wait_time
wait_time /= 100

while (timeout = deadline - Time.now()) > 0
  begin
    Timeout.timeout(timeout) do
      begin
        TCPSocket.new(server, port).close()
        exit(0)
      rescue Errno::ETIMEDOUT
      rescue
        sleep(wait_time)
      end
    end
  rescue Timeout::Error
    break
  end
end

exit(1)
