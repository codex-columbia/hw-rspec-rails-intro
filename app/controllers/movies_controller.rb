class MoviesController < ApplicationController
  before_action :force_index_redirect, only: [:index]

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    @all_ratings = Movie.all_ratings
    @movies = Movie.with_ratings(ratings_list, sort_by)
    @ratings_to_show_hash = ratings_hash
    @sort_by = sort_by
    # remember the correct settings for next time
    session['ratings'] = ratings_list
    session['sort_by'] = @sort_by
  end

  def new
    # default: render 'new' template
  end

  def create
    @movie = Movie.create!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  # Search for movies in TMDb
  def search_tmdb
    # Display the search form if no search has been submitted
    return unless params.key?(:title)

    # Make sure the required title field is not empty
    if params[:title].blank?
      flash.now[:danger] = 'Please fill in all required fields!'
      return
    end

    # Collect search parameters
    options = {
      title: params[:title].strip,
      release_year: params[:release_year],
      language: params[:language]
    }

    # Search TMDb using the Movie model
    @movies = Movie.find_in_tmdb(options)

    # Display a message if no movies match the search
    if @movies.empty?
      flash.now[:warning] = 'No movies found with given parameters!'
    end

  rescue Movie::TMDbError, Faraday::Error, JSON::ParserError
    flash.now[:danger] = 'TMDb search failed. Please try again.'
  end

  # Add a movie from TMDb search results to the database
  def add_movie
    @movie = Movie.new(movie_params)

    if @movie.save
      flash[:success] = "#{@movie.title} was successfully added to RottenPotatoes."
    else
      flash[:danger] = 'Unable to add movie.'
    end

    # Return to the search page
    redirect_to search_tmdb_path
  end

  private

  def force_index_redirect
    return unless !params.key?(:ratings) || !params.key?(:sort_by)

    flash.keep
    url = movies_path(sort_by: sort_by, ratings: ratings_hash)
    redirect_to url
  end

  def ratings_list
    params[:ratings]&.keys || session[:ratings] || Movie.all_ratings
  end

  def ratings_hash
    ratings_list.to_h { |item| [item, "1"] }
  end

  def sort_by
    params[:sort_by] || session[:sort_by] || 'id'
  end

  # Permit the fields required to create or update a movie
  def movie_params
    params.require(:movie).permit(
      :title,
      :rating,
      :release_date,
      :description
    )
  end
end
