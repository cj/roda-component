require 'pry'
require 'awesome_print'
require './constants'

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

require './app'

run TestApp
