require 'sinatra/base'
require ::File.expand_path('../lib/month', __FILE__)

WEEKLY_BASE_URL = "http://localhost:8080/weekly"

class MyCal < Sinatra::Application
  get '/calendar/:first_day_of_month' do
    @this_month = Month.starting_on(params[:first_day_of_month])

    erb :calendar
  end
end
