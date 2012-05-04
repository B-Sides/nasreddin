class WeekdaysController < ApplicationController
  def index
    @weekdays = Weekday.all
    respond_to do |format|
      format.html
      format.json { render json: @weekdays }
    end
  end

  def show
    @weekday = Weekday.find_by_id(params[:id].to_i)
    respond_to do |format|
      format.html
      format.json { render json: @weekday }
    end
  end
end
