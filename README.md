> "Nasreddin, your donkey has been lost."

> "Thank goodness I was not on the donkey at the time, or I would be lost too."


## What is Nasreddin?

Nasreddin Hoca was a wise scolar from 13th century Anatolia. This, however, is a library designed to enable know-nothing
distribution of data requests between varying services.

To connect two services, one needs to include the Nasreddin::APIServer middleware and indicate what resources it is offering:
```ruby
require 'nasreddin/api-server'

use Nasreddin::APIServer, resources: %w| users |
run MyApp
```
Then, the consumer can use the Nasreddin::Resource class to generate new classes that will talk to the APIServer when making
requests.


An example implementation of Nasreddin::Resource is provided below

```ruby
require 'nasreddin/resource'

class User < Nasreddin::Resource('users') # name of endpoint for resource
end

```
