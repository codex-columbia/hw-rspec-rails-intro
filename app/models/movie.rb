require 'json'
require 'date'
require 'faraday'

class Movie < ActiveRecord::Base
  class TMDbError < StandardError; end

  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end

  def self.find_in_tmdb(options, api_key = ENV['TMDB_API_KEY'])
    if api_key.blank?
      raise TMDbError, 'Missing TMDb API key'
    end

    query_params = {
      api_key: api_key,
      query: options[:title]
    }

    if options[:release_year].present?
      query_params[:year] = options[:release_year]
    end

    if options[:language] == 'en'
      query_params[:language] = 'en-US'
    end

    response = Faraday.get(
      'https://api.themoviedb.org/3/search/movie',
      query_params
    )

    unless response.status == 200
      raise TMDbError, "TMDb returned status #{response.status}"
    end

    data = JSON.parse(response.body)
    results = data.fetch('results', [])

    results.map do |result|
      release_date = nil

      if result['release_date'].present?
        begin
          release_date = Date.iso8601(result['release_date'])
        rescue Date::Error
          release_date = nil
        end
      end

      Movie.new(
        title: result['title'],
        rating: 'R',
        release_date: release_date,
        description: result['overview']
      )
    end
  end
end