require 'rails_helper'
require 'spec_helper'

RSpec.describe Movie, type: :model do
  describe 'searching TMDb' do
    let(:options) do
      {
        title: 'Olympics',
        release_year: '2000',
        language: 'en'
      }
    end

    it 'calls Faraday to perform the search' do
      expect(Faraday).to receive(:get).and_call_original

      Movie.find_in_tmdb(options, 'test-key')
    end

    it 'sends the correct query parameters' do
      Movie.find_in_tmdb(options, 'test-key')

      expect(
        a_request(:get, 'https://api.themoviedb.org/3/search/movie')
          .with(query: {
            api_key: 'test-key',
            query: 'Olympics',
            year: '2000',
            language: 'en-US'
          })
      ).to have_been_made.once
    end

    it 'allows the release year to be omitted' do
      Movie.find_in_tmdb(
        {title: 'Olympics', release_year: '', language: 'all'},
        'test-key'
      )

      expect(
        a_request(:get, 'https://api.themoviedb.org/3/search/movie')
          .with(query: {
            api_key: 'test-key',
            query: 'Olympics'
          })
      ).to have_been_made.once
    end

    it 'returns unsaved Movie objects with R ratings' do
      original_count = Movie.count

      results = Movie.find_in_tmdb(options, 'test-key')

      expect(results.length).to eq(2)
      expect(results).to all(be_a(Movie))
      expect(results).to all(be_new_record)
      expect(results.map(&:rating)).to all(eq('R'))
      expect(Movie.count).to eq(original_count)

      expect(results.first.title).to eq(
        'Sydney 2000 Olympics Opening Ceremony'
      )
    end

    it 'returns an empty array if there are no matches' do
      stub_request(:get, /api\.themoviedb\.org/)
        .to_return(
          status: 200,
          body: '{"results":[]}',
          headers: {'Content-Type' => 'application/json'}
        )

      results = Movie.find_in_tmdb(options, 'test-key')

      expect(results).to eq([])
    end

    it 'raises an error for an invalid API key' do
      stub_request(:get, /api\.themoviedb\.org/)
        .to_return(
          status: 401,
          body: '{"status_message":"Invalid API key"}'
        )

      expect {
        Movie.find_in_tmdb(options, 'invalid-key')
      }.to raise_error(Movie::TMDbError)
    end
  end
end