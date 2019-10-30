Rails.application.routes.draw do
  root to: 'unit#index'
  post '/webhooks/event', to: 'unit#event'
  post '/webhooks/answer', to: 'unit#answer'
  post '/authenticate', to: 'unit#authenticate'
  post '/menu-choice', to: 'unit#menu'
end
