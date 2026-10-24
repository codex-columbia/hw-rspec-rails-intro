
require 'rails_helper'

RSpec.describe MoviesController, type: :controller do
  describe 'searching TMDb' do
    before :each do
      @fake_results = [
        double('movie1'),
        double('movie2')
      ]
    end

    it 'calls the model method that performs TMDb search' do
      expect(Movie).to receive(:find_in_tmdb).with({
        title: 'hardware',
        release_year: '1986',
        language: 'en'
      }).and_return(@fake_results)

      get :search_tmdb, params: {
        title: 'hardware',
        release_year: '1986',
        language: 'en'
      }
    end

    describe 'after valid search' do
      before :each do
        allow(Movie).to receive(:find_in_tmdb)
          .and_return(@fake_results)

        get :search_tmdb, params: {
          title: 'hardware',
          release_year: '',
          language: 'all'
        }
      end

      it 'selects the Search Results template for rendering' do
        expect(response).to render_template('search_tmdb')
      end

      it 'makes the TMDb search results available to the template' do
        expect(assigns(:movies)).to eq(@fake_results)
      end
    end

    it 'shows an error if title is blank' do
      expect(Movie).not_to receive(:find_in_tmdb)

      get :search_tmdb, params: {
        title: '',
        release_year: '2000',
        language: 'all'
      }

      expect(flash[:danger]).to eq(
        'Please fill in all required fields!'
      )
    end

    it 'shows an error when no movies are found' do
      allow(Movie).to receive(:find_in_tmdb).and_return([])

      get :search_tmdb, params: {
        title: 'Unknown Movie',
        language: 'all'
      }

      expect(flash[:warning]).to eq(
        'No movies found with given parameters!'
      )
    end

    it 'shows the empty search form on initial visit' do
      expect(Movie).not_to receive(:find_in_tmdb)

      get :search_tmdb

      expect(response).to render_template('search_tmdb')
    end
  end

  describe 'adding a movie' do
    it 'saves the movie and redirects to search' do
      movie_attributes = {
        title: 'Test Movie',
        rating: 'R',
        release_date: '2000-09-15',
        description: 'Test description'
      }

      expect {
        post :add_movie, params: {movie: movie_attributes}
      }.to change(Movie, :count).by(1)

      expect(response).to redirect_to(search_tmdb_path)
      expect(flash[:success]).to eq(
        'Test Movie was successfully added to RottenPotatoes.'
      )
    end
  end
end
