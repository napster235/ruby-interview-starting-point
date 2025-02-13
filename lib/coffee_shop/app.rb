# frozen_string_literal: true

require 'haml'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/param'
require 'net/http'
require 'uri'

module CoffeeShop
  class App < Sinatra::Base
    helpers Sinatra::Param

    URL = 'https://raw.githubusercontent.com/Agilefreaks/test_oop/master/coffee_shops.csv'

    get '/' do
      @coffee_shops = read_coffee_shop_csv
      haml :index
    end

    get '/search' do
      param :latitude, Float, min: -90, max: 90, required: !params[:longitude].nil?
      param :longitude, Float, min: -180, max: 180, required: !params[:latitude].nil?

      @latitude = params[:latitude]
      @longitude = params[:longitude]

      coffee_shop_csv_data = read_coffee_shop_csv

      unless coffee_shop_csv_data.nil?
        @coffee_shops = nearest({ latitude: @latitude, longitude: @longitude }, coffee_shop_csv_data)
      end

      haml :search
    end

    private

    def read_coffee_shop_csv
      coffee_shops_data = fetch_csv_data(URL)
      return if coffee_shops_data.nil?

      parse_coffee_shops_data(coffee_shops_data)
    end

    def fetch_csv_data(url)
      Net::HTTP.get(URI.parse(url))
    rescue SocketError => e
      puts e.to_s
    end

    def parse_coffee_shops_data(coffee_shops_data)
      csv_data = coffee_shops_data.split("\n").map { |line| line.split(',') }
      csv_data.map do |elem|
        { name: elem[0], latitude: elem[1].to_f, longitude: elem[2].to_f }
      end
    end

    def distance(point1, point2)
      Math.sqrt(
        ((point1[:longitude] - point2[:longitude])**2) + ((point1[:latitude] - point2[:latitude])**2)
      ).round(4)
    end

    def nearest(origin, points)
      return if params[:latitude].nil? && params[:longitude].nil?

      data = points.map do |point|
        point.merge({ distance: distance(point, origin) })
      end
      data.sort { |a, b| a[:distance] <=> b[:distance] }.slice(0, 3)
    end
  end
end
