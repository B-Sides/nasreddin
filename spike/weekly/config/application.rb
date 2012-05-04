require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"

# Auto-require default libraries and those for the current Rails environment. 
Bundler.require :default, Rails.env

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module Weekly
  class Application < Rails::Application
    # Use TorqueBox::Infinispan::Cache for the Rails cache store
    config.cache_store = :torque_box_store

    config.encoding = "utf-8"
  end
end
