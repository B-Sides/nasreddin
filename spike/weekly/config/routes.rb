Weekly::Application.routes.draw do
  resources :weekdays, only: [:index, :show]
end
