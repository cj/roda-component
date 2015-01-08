require 'pry'
require 'awesome_print'
require 'rack/unreloader'
require './constants'
require './app'

Unreloader = Rack::Unreloader.new(:logger=>Logger.new($stdout)){TestApp}
Unreloader.require './app.rb'
Unreloader.require './components'
Unreloader.require './models'
Unreloader.require '../../lib/roda/component/dom.rb'
Unreloader.require '../../lib/roda/component/faye.rb'
Unreloader.require '../../lib/roda/component.rb'
Unreloader.require '../../lib/roda/plugins/component.rb'

run Unreloader
