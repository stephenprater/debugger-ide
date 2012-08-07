require 'pry'

$: << File.expand_path('../lib',File.dirname(__FILE__))
require 'debugger-ide'

puts "hi I am a test application"

trap "INT" do
  exit
end

i = 0

loop do
  sleep 0.1
  i += 1
end

at_exit do
  puts "end of line"
end
