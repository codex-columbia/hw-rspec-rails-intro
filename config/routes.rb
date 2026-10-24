Rottenpotatoes::Application.routes.draw do
  get '/search', to: 'movies#search_tmdb', as: 'search_tmdb'
  post '/add_movie', to: 'movies#add_movie', as: 'add_movie'

  resources :movies

  root to: redirect('/movies')
end