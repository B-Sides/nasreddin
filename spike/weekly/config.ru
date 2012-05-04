require ::File.expand_path('../config/environment',  __FILE__)
require 'nasreddin/api-server'

puts "\n" + "*"*10 + "\nGO RAILS GO!\n" + "*"*10

use Nasreddin::APIServer

run Weekly::Application
