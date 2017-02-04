Rails.application.routes.draw do
  resource :training, only: [:show]

  root 'races#show'
end
