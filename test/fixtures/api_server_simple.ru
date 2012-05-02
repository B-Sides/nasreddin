require 'nasreddin/api_server'

use Rack::Lint
use Nasreddin::APIServer
use Rack::Lint

run ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }

